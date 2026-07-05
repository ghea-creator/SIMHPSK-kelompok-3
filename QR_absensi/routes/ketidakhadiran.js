const axios = require('axios');

// Endpoint ketidakhadiran - terpisah untuk menghindari character encoding issues

module.exports = function(app, getDb, verifyToken, checkDbReady) {
  
  app.get("/ketidakhadiran", verifyToken, checkDbReady, async (req, res) => {
    try {
      const db = typeof getDb === 'function' ? getDb() : getDb;
      if (req.user.role !== 'admin') {
        return res.status(403).json({ message: "Hanya admin yang dapat melihat data ketidakhadiran." });
      }

      // Get date from query, default today (Jakarta time)
      const now = new Date();
      const jakartaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
      const todayStr = `${jakartaNow.getFullYear()}-${String(jakartaNow.getMonth()+1).padStart(2,'0')}-${String(jakartaNow.getDate()).padStart(2,'0')}`;
      const currentTimeStr = `${String(jakartaNow.getHours()).padStart(2,'0')}:${String(jakartaNow.getMinutes()).padStart(2,'0')}:00`;

      const queryDate = req.query.tanggal || todayStr;

      // Get settings for ongoing check
      const [workSettingsRows] = await db.query('SELECT * FROM settings_kerja LIMIT 1');
      const settings = workSettingsRows[0];
      const jamMasukAkhir = settings ? String(settings.jam_masuk_akhir) : '10:00:00';
      const normalizeT = (t) => t && t.length === 5 ? t + ':00' : (t || '10:00:00');
      const jamMasukAkhirNorm = normalizeT(jamMasukAkhir);

      // Check Future Date
      if (queryDate > todayStr) {
        return res.json({
          tanggal: queryDate,
          is_holiday: true,
          holiday_type: 'future',
          holiday_name: 'Absensi Belum Mulai',
          keterangan: 'Tanggal terpilih berada di masa depan. Data absensi dan ketidakhadiran belum tersedia.',
          total_tidak_hadir: 0,
          data: []
        });
      }

      // Check if session is still ongoing for today
      if (queryDate === todayStr && currentTimeStr < jamMasukAkhirNorm) {
        return res.json({
          tanggal: queryDate,
          is_holiday: true,
          holiday_type: 'ongoing',
          holiday_name: 'Sesi Absen Masuk Sedang Berlangsung',
          keterangan: `Sesi absensi masuk masih dibuka sampai pukul ${jamMasukAkhirNorm.slice(0, 5)}. Data ketidakhadiran otomatis (Alpa) akan dihitung setelah batas waktu absen berakhir.`,
          total_tidak_hadir: 0,
          data: []
        });
      }

      // Check weekend
      const d = new Date(queryDate + 'T00:00:00');
      const dayOfWeek = d.getDay(); // 0 = Sunday, 6 = Saturday
      if (dayOfWeek === 0 || dayOfWeek === 6) {
        return res.json({
          tanggal: queryDate,
          is_holiday: true,
          holiday_type: 'weekend',
          holiday_name: 'Akhir Pekan',
          keterangan: `Hari ${dayOfWeek === 0 ? "Minggu" : "Sabtu"} adalah akhir pekan (libur).`,
          total_tidak_hadir: 0,
          data: []
        });
      }

      // Check Holiday
      let isHoliday = false;
      let holidayName = "";
      try {
        const year = d.getFullYear();
        const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
        if (holidayResponse.data && holidayResponse.data.status === "success") {
          const holiday = holidayResponse.data.data.find(h => h.date === queryDate);
          if (holiday) {
            isHoliday = true;
            holidayName = holiday.description;
          }
        }
      } catch (apiErr) {
        console.error("Gagal mengambil data libur nasional:", apiErr.message);
      }

      if (isHoliday) {
        return res.json({
          tanggal: queryDate,
          is_holiday: true,
          holiday_type: 'national',
          holiday_name: holidayName,
          keterangan: `Hari Libur Nasional: ${holidayName}`,
          total_tidak_hadir: 0,
          data: []
        });
      }

      console.log('🧾 [ketidakhadiran] req.user.role:', req.user.role, 'tanggal=', queryDate);
      
      // Get all employees
      const [allPegawai] = await db.query(`
        SELECT id, nama, jabatan, divisi_id, foto 
        FROM pegawai 
        ORDER BY nama ASC
      `);

      // Get all who have attended today
      const [hadir] = await db.query(`
        SELECT DISTINCT pegawai_id 
        FROM absensi 
        WHERE tanggal = ? AND status = 'Hadir'
      `, [queryDate]);

      const hadirIds = new Set(hadir.map(h => h.pegawai_id));

      console.log('📌 [ketidakhadiran] allPegawai=', allPegawai?.length, 'hadirCount=', hadir?.length);

      // Build set for not-hadir candidates so we can filter at the end if needed
      // (Alpa/Izin/Sakit/Cuti Tambahan can exist, but Hadir must take priority)



      // 1. Get all Sakit/Izin records on this date
      const [izinSakitRecords] = await db.query(`
        SELECT pegawai_id, status, alasan, foto_bukti 
        FROM absensi 
        WHERE tanggal = ? AND (status = 'Sakit' OR status = 'Izin')
        ORDER BY pegawai_id
      `, [queryDate]);

      // 2. Get all Alpa records on this date
      const [alpaRecords] = await db.query(`
        SELECT pegawai_id, status, alasan, foto_bukti 
        FROM absensi 
        WHERE tanggal = ? AND status = 'Alpa'
        ORDER BY pegawai_id
      `, [queryDate]);

      // 3. Get all approved additional leaves (Cuti Tambahan) that span this date
      // Use LOWER() for robustness against casing/typos in DB
      const [cutiTambahanRecords] = await db.query(`
        SELECT pegawai_id, keperluan as jenis_cuti, alasan, foto_bukti, tanggal_mulai, tanggal_selesai
        FROM cuti_tambahan 
        WHERE LOWER(status) = 'disetujui' 
        AND tanggal_mulai <= ? 
        AND tanggal_selesai >= ?
        ORDER BY pegawai_id
      `, [queryDate, queryDate]);



      // Create a map of pegawai with their absence details
      const ketidakhadiranMap = {};

      // If a pegawai has status Hadir on that date, they should not be counted as not hadir
      const hadirSet = hadirIds;

      // Process Izin/Sakit records
      izinSakitRecords.forEach(record => {
        if (hadirSet.has(record.pegawai_id)) return;


        if (!ketidakhadiranMap[record.pegawai_id]) {
          ketidakhadiranMap[record.pegawai_id] = {
            pegawai_id: record.pegawai_id,
            records: []
          };
        }
        ketidakhadiranMap[record.pegawai_id].records.push({
          type: 'izin', // Combined Sakit and Izin into 'izin'
          status: record.status,
          alasan: record.alasan,
          foto_bukti: record.foto_bukti
        });
      });

      // Process Alpa records
      alpaRecords.forEach(record => {
        if (hadirSet.has(record.pegawai_id)) return;

        if (!ketidakhadiranMap[record.pegawai_id]) {
          ketidakhadiranMap[record.pegawai_id] = {
            pegawai_id: record.pegawai_id,
            records: []
          };
        }

        ketidakhadiranMap[record.pegawai_id].records.push({
          type: 'alpa',
          status: record.status,
          alasan: record.alasan,
          foto_bukti: record.foto_bukti
        });
      });

      // Process Cuti Tambahan records
      cutiTambahanRecords.forEach(record => {
        if (!ketidakhadiranMap[record.pegawai_id]) {
          ketidakhadiranMap[record.pegawai_id] = {
            pegawai_id: record.pegawai_id,
            records: []
          };
        }
        ketidakhadiranMap[record.pegawai_id].records.push({
          type: 'cuti',
          jenis_cuti: record.jenis_cuti,
          alasan: record.alasan,
          foto_bukti: record.foto_bukti,
          tanggal_mulai: record.tanggal_mulai,
          tanggal_selesai: record.tanggal_selesai
        });
      });

      const isPastOrClosed = (queryDate < todayStr) || 
                             (queryDate === todayStr && currentTimeStr >= jamMasukAkhirNorm);

      if (isPastOrClosed) {
        // Process remaining employees who are not present and have no excuse/leave record
        allPegawai.forEach(pegawai => {
          if (hadirSet.has(pegawai.id)) return;

          if (!ketidakhadiranMap[pegawai.id]) {
            ketidakhadiranMap[pegawai.id] = {
              pegawai_id: pegawai.id,
              records: [{
                type: 'alpa',
                status: 'Alpa',
                alasan: 'Tidak melakukan absensi',
                foto_bukti: null
              }]
            };
          }
        });
      }

      // Build the response data with employee info + absence details
      const ketidakhadirData = [];
      
      Object.values(ketidakhadiranMap).forEach(item => {
        const pegawai = allPegawai.find(p => p.id === item.pegawai_id);
        if (pegawai) {
          ketidakhadirData.push({
            id: pegawai.id,
            nama: pegawai.nama,
            jabatan: pegawai.jabatan,
            divisi_id: pegawai.divisi_id,
            foto: pegawai.foto,
            absences: item.records // Array of absence records with details
          });
        }
      });

      res.json({
        tanggal: queryDate,
        total_tidak_hadir: ketidakhadirData.length,
        data: ketidakhadirData
      });
    } catch (err) {
      console.error("Error fetching ketidakhadiran:", err);
      res.status(500).json({ message: err.message });
    }
  });
};
