import { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import QRCode from 'qrcode';
import { Html5QrcodeScanner } from 'html5-qrcode';

// Helper: dapatkan tanggal hari ini dalam format YYYY-MM-DD berdasarkan waktu LOKAL (bukan UTC)
function getLocalDateStr(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function App() {
  // ==========================================
  // AUTHENTICATION & ROLE STATE
  // ==========================================
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [role, setRole] = useState(localStorage.getItem('role') || '');
  const [username, setUsername] = useState(localStorage.getItem('username') || '');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  // ==========================================
  // DASHBOARD TABS & GENERAL LISTS
  // ==========================================
  const [activeTab, setActiveTab] = useState('pegawai');
  const [userTab, setUserTab] = useState('presensi'); // 'presensi' | 'cuti'
  const [pegawai, setPegawai] = useState([]);
  const [divisi, setDivisi] = useState([]);
  const [absensi, setAbsensi] = useState([]);
  const [cuti, setCuti] = useState([]);
  const [ketidakhadiran, setKetidakhadiran] = useState([]);
  const [ketidakhadiranDate, setKetidakhadiranDate] = useState(getLocalDateStr());
  const [holidayInfo, setHolidayInfo] = useState(null); // { is_holiday, holiday_type, holiday_name, keterangan }

  // ==========================================
  // FORM STATE: PEGAWAI (ADMIN)
  // ==========================================
  const [pegawaiSearch, setPegawaiSearch] = useState('');
  
  // Office QR Code state
  const [officeQrCode, setOfficeQrCode] = useState('');
  const [qrEligibility, setQrEligibility] = useState({ loading: false, eligible: false, reason: '', date: '' });

  // Ganti Password (Employee)
  const [isChangePasswordOpen, setIsChangePasswordOpen] = useState(false);
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  
  // Settings Page (Employee/User)
  const [settingsOldPassword, setSettingsOldPassword] = useState('');
  const [settingsNewPassword, setSettingsNewPassword] = useState('');
  const [settingsConfirmPassword, setSettingsConfirmPassword] = useState('');
  const [isUploadingUserFoto, setIsUploadingUserFoto] = useState(false);
  const [settingsUserFoto, setSettingsUserFoto] = useState('');
  const [showPasswordFields, setShowPasswordFields] = useState(false);
  const [showAdminOldPass, setShowAdminOldPass] = useState(false);
  const [showAdminNewPass, setShowAdminNewPass] = useState(false);
  const [showAdminConfirmPass, setShowAdminConfirmPass] = useState(false);
  const [showUserOldPass, setShowUserOldPass] = useState(false);
  const [showUserNewPass, setShowUserNewPass] = useState(false);
  const [showTambahPass, setShowTambahPass] = useState(false);
  const [showTambahConfirmPass, setShowTambahConfirmPass] = useState(false);
  const [showEditLoginPass, setShowEditLoginPass] = useState(false);
  const [showEditLoginConfirmPass, setShowEditLoginConfirmPass] = useState(false);
  const [showEmpOldPass, setShowEmpOldPass] = useState(false);
  const [showEmpNewPass, setShowEmpNewPass] = useState(false);
  

  
  // Modals for Pegawai (Admin)
  const [activeQrEmployee, setActiveQrEmployee] = useState(null);
  const [adminQrSrc, setAdminQrSrc] = useState('');
  const [activeDetailEmployee, setActiveDetailEmployee] = useState(null);
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [editJabatan, setEditJabatan] = useState('');
  const [editDivisiId, setEditDivisiId] = useState('');
  const [editFoto, setEditFoto] = useState('');
  const [isUploadingFoto, setIsUploadingFoto] = useState(false);
  const [showLoginModal, setShowLoginModal] = useState(null);

  // ==========================================
  // FORM STATE: DIVISI (ADMIN)
  // ==========================================
  const [namaDivisi, setNamaDivisi] = useState('');

  // ==========================================
  // FORM STATE: ABSENSI (ADMIN)
  // ==========================================
  const [absensiPegawaiId, setAbsensiPegawaiId] = useState('');
  const [absensiTanggal, setAbsensiTanggal] = useState(getLocalDateStr());
  const [absensiJamMasuk, setAbsensiJamMasuk] = useState('08:00');
  const [absensiJamKeluar, setAbsensiJamKeluar] = useState('17:00');
  const [absensiStatus, setAbsensiStatus] = useState('Hadir');
  const [searchAbsensi, setSearchAbsensi] = useState('');
  const [activeAbsensiEmployee, setActiveAbsensiEmployee] = useState(null);

  // ==========================================
  // FORM STATE: CUTI BIASA & CUTI TAMBAHAN (USER/PEGAWAI)
  // ==========================================
  const todayStr = getLocalDateStr();
  const [biasaTanggalMulai, setBiasaTanggalMulai] = useState(todayStr);
  const [biasaTanggalSelesai, setBiasaTanggalSelesai] = useState(todayStr);
  const [biasaStatus, setBiasaStatus] = useState('Izin');
  const [biasaAlasan, setBiasaAlasan] = useState('');
  const [biasaFotoBukti, setBiasaFotoBukti] = useState('');

  const [tambahanTanggalMulai, setTambahanTanggalMulai] = useState(todayStr);
  const [tambahanTanggalSelesai, setTambahanTanggalSelesai] = useState(todayStr);
  const [tambahanKeperluan, setTambahanKeperluan] = useState('Izin/Sakit Lanjutan');
  const [tambahanAlasan, setTambahanAlasan] = useState('');
  const [tambahanFotoBukti, setTambahanFotoBukti] = useState('');

  const [biasaWarning, setBiasaWarning] = useState({ show: false, message: '' });
  const [tambahanWarning, setTambahanWarning] = useState({ show: false, message: '' });

  // Image viewer overlay state
  const [previewImage, setPreviewImage] = useState(null);
  const [previewAlasan, setPreviewAlasan] = useState(null);

  // ==========================================
  // CUTI NOTIFICATION (ACC / DITOLAK) - USER
  // ==========================================
  const [cutiNotifs, setCutiNotifs] = useState([]); // list dari GET /cuti/notif
  const [cutiNotifModal, setCutiNotifModal] = useState(null); // satu notif untuk modal
  const [isCutiNotifLoading, setIsCutiNotifLoading] = useState(false);
  const [isCutiNotifMarkingRead, setIsCutiNotifMarkingRead] = useState(false);



  // Izin/Sakit Modal state
  const [izinSakitModal, setIzinSakitModal] = useState({ show: false, type: '' }); // type: 'Izin' or 'Sakit'
  const [izinSakitAlasan, setIzinSakitAlasan] = useState('');
  const [izinSakitFoto, setIzinSakitFoto] = useState('');
  const [izinSakitTanggalMulai, setIzinSakitTanggalMulai] = useState('');
  const [izinSakitTanggalSelesai, setIzinSakitTanggalSelesai] = useState('');

  // Admin approval confirmation modal (untuk izin/sakit & cuti tambahan)
  const [approvalModal, setApprovalModal] = useState(null); // { type: 'izin'|'cuti', data: {...} }

  // Multi-select cuti untuk approval multiple
  const [selectedCutiIds, setSelectedCutiIds] = useState(new Set());
  const [cutiSortBy, setCutiSortBy] = useState('terbaru'); // 'terbaru', 'durasi_lama', 'durasi_pendek'
  const [cutiFilterBy, setCutiFilterBy] = useState('semua'); // 'semua', 'pending', '1-3hari', '4-7hari', '7plus'

  // File to Base64 helper
  const handleFileToBase64 = (file, callback) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => callback(reader.result);
    reader.onerror = (error) => console.error('Error converting file to base64:', error);
  };

  // ==========================================
  // USER / EMPLOYEE PROFILE STATE
  // ==========================================
  const [currentEmployee, setCurrentEmployee] = useState(null);
  const [employeeQrCode, setEmployeeQrCode] = useState('');
  const [isScannerOpen, setIsScannerOpen] = useState(false);
  const [showOutsideHoursModal, setShowOutsideHoursModal] = useState(false);
  const [outsideHoursData, setOutsideHoursData] = useState(null);
  const userScannerRef = useRef(null);
  const [userScannerKey, setUserScannerKey] = useState(0);

  // ==========================================
  // QR CODE MANAGEMENT STATE (ADMIN & USER)
  // ==========================================
  const [qrCodeList, setQrCodeList] = useState([]);
  const [selectedUserForQr, setSelectedUserForQr] = useState('');
  const [qrPegawaiSearch, setQrPegawaiSearch] = useState('');
  const [qrTanggalBerlaku, setQrTanggalBerlaku] = useState(getLocalDateStr());
  const [generatedQrCode, setGeneratedQrCode] = useState('');
  const [generatedQrImage, setGeneratedQrImage] = useState('');
  const [isQrScannerOpen, setIsQrScannerOpen] = useState(false);
  const [qrScannerResult, setQrScannerResult] = useState('');
  const adminScannerRef = useRef(null);
  const [adminScannerKey, setAdminScannerKey] = useState(0);

  // ==========================================
  // DIRECT USER CREATION STATE (ADMIN)
  // ==========================================
  const [newUserUsername, setNewUserUsername] = useState('');
  const [newUserPassword, setNewUserPassword] = useState('');
  const [newUserConfirmPassword, setNewUserConfirmPassword] = useState('');
  const [newUserNama, setNewUserNama] = useState('');
  const [newUserDivisiId, setNewUserDivisiId] = useState('');
  const [newUserJabatan, setNewUserJabatan] = useState('');
  const [isCreatingUser, setIsCreatingUser] = useState(false);

  // ==========================================
  // REKAP BULANAN MONTH SELECTOR STATE & HELPER
  // ==========================================
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`; // YYYY-MM
  });

  // ==========================================
  // RIWAYAT ABSENSI USER - WEEKLY VIEW
  // ==========================================
  // Tanggal yang dicari via kalender (YYYY-MM-DD), default hari ini
  const [riwayatSearchDate, setRiwayatSearchDate] = useState(() => getLocalDateStr());
  // Indeks minggu yang aktif (0 = minggu paling baru dalam hasil pencarian)
  const [riwayatWeekIndex, setRiwayatWeekIndex] = useState(0);

  // Mode rekap: 'harian' atau 'bulanan'
  const [rekapMode, setRekapMode] = useState('harian');
  // Tanggal terpilih untuk mode harian
  const [selectedDate, setSelectedDate] = useState(getLocalDateStr()); // YYYY-MM-DD

  const getMonthOptions = () => {
    const options = [];
    const now = new Date();
    for (let i = 0; i < 12; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      const label = d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
      options.push({ value, label });
    }
    return options;
  };

  // ==========================================
  // WORK HOURS SETTINGS STATE (ADMIN)
  // ==========================================
  const [workSettings, setWorkSettings] = useState({
    jam_masuk_awal: '07:00',
    jam_masuk_akhir: '09:00',
    jam_keluar_awal: '16:00',
    jam_keluar_akhir: '17:00'
  });
  const [editingWorkSettings, setEditingWorkSettings] = useState(false);
  const [tempWorkSettings, setTempWorkSettings] = useState({ ...workSettings });

  // ==========================================
  // TOAST / FLOATING ALERTS STATE
  // ==========================================
  const [toast, setToast] = useState({ show: false, message: '', type: 'success' });
  const [showQuotaAlert, setShowQuotaAlert] = useState(false);

  // ==========================================
  // CUSTOM DIALOG MODAL (pengganti window.confirm & alert)
  // ==========================================
  const [customAlert, setCustomAlert] = useState({ show: false, title: '', message: '' });
  const [customConfirm, setCustomConfirm] = useState({ show: false, title: '', message: '', onConfirm: null });

  function showCustomAlert(message, title = 'Informasi') {
    setCustomAlert({ show: true, title, message });
  }

  function showCustomConfirm(message, onConfirm, title = 'Konfirmasi') {
    console.log("showCustomConfirm called with:", { message, title });
    setCustomConfirm({ show: true, title, message, onConfirm });
  }

  function showToast(message, type = 'success') {
    setToast({ show: true, message, type });
    setTimeout(() => {
      setToast({ show: false, message: '', type: 'success' });
    }, 4000);
  }

  // ==========================================
  // SYNC EFFECTS
  // ==========================================
  useEffect(() => {
    if (token) {
      loadAllData();
      if (role === 'user') {
        // load cuti notifications on login
        getCutiNotifs();
      }
    }
  }, [token, role]);

  // Clean up theme settings to ensure always light mode
  useEffect(() => {
    document.documentElement.removeAttribute('data-theme');
    localStorage.removeItem('theme');
  }, []);

  // Effect to validate Cuti Biasa and show modal popup immediately
  useEffect(() => {
    if (role === 'user' && biasaTanggalMulai && biasaTanggalSelesai) {
      const start = new Date(biasaTanggalMulai);
      const end = new Date(biasaTanggalSelesai);
      const duration = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
      const sisa = getSisaKuotaBiasa();
      if (duration > 0 && duration > sisa) {
        setBiasaWarning({
          show: true,
          message: `Jatah Habis! Tidak bisa mengirim pengajuan karena durasi cuti biasa (${duration} hari) melebihi sisa jatah kuota Anda (${sisa} hari).`
        });
      } else {
        setBiasaWarning({ show: false, message: '' });
      }
    } else {
      setBiasaWarning({ show: false, message: '' });
    }
  }, [biasaTanggalMulai, biasaTanggalSelesai, absensi, cuti, role, currentEmployee]);

  useEffect(() => {
    if (role === 'user' && tambahanTanggalMulai && tambahanTanggalSelesai && tambahanKeperluan === 'Izin/Sakit Lanjutan') {
      const start = new Date(tambahanTanggalMulai);
      const end = new Date(tambahanTanggalSelesai);
      const duration = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
      if (duration > 5) {
        setTambahanWarning({
          show: true,
          message: `Batas Terlewati! Durasi pengajuan Cuti Tambahan (${duration} hari) melebihi batas maksimal 5 hari untuk kategori Izin/Sakit Lanjutan. Tidak bisa mengirim pengajuan.`
        });
      } else {
        setTambahanWarning({ show: false, message: '' });
      }
    } else {
      setTambahanWarning({ show: false, message: '' });
    }
  }, [tambahanTanggalMulai, tambahanTanggalSelesai, tambahanKeperluan, role]);

  // Effect to show quota warning popup once per login session
  useEffect(() => {
    if (role === 'user' && token && pegawai.length > 0 && absensi.length > 0) {
      const loggedInName = localStorage.getItem('username') || username;
      const matchedEmployee = pegawai.find(
        (p) => p.username && p.username.toLowerCase() === loggedInName.toLowerCase()
      );
      const myName = matchedEmployee ? matchedEmployee.nama : loggedInName;
      const myLogs = absensi.filter((a) => a.nama.toLowerCase() === myName.toLowerCase());
      // Combine Sakit and Izin into single Izin count
      const countIzin = myLogs.filter((l) => l.status === 'Izin' || l.status === 'Sakit').length;
      
      const myCuti = cuti.filter((c) => c.nama.toLowerCase() === myName.toLowerCase());
      const approvedCutiDays = myCuti
        .filter((c) => c.status === 'Disetujui')
        .reduce((sum, current) => sum + parseInt(current.durasi_hari), 0);

      const totalLeaveCount = countIzin;
      const quotaLimit = 7 + approvedCutiDays;

      if (totalLeaveCount >= quotaLimit) {
        const alertShown = sessionStorage.getItem('quotaAlertShown');
        if (!alertShown) {
          setShowQuotaAlert(true);
          sessionStorage.setItem('quotaAlertShown', 'true');
        }
      } else {
        sessionStorage.removeItem('quotaAlertShown');
      }
    }
  }, [role, token, pegawai, absensi, cuti, username]);

  // Load employee detail for role === 'user'
  useEffect(() => {
    if (role === 'user' && pegawai.length > 0) {
      const loggedInUser = localStorage.getItem('username') || username;
      const matched = pegawai.find(
        (p) => p.username && p.username.toLowerCase() === loggedInUser.toLowerCase()
      );
      if (matched) {
        setCurrentEmployee(matched);
        // Generate Personal QR Code
        const qrData = JSON.stringify({
          id: matched.id,
          nama: matched.nama,
          jabatan: matched.jabatan,
          divisi: matched.nama_divisi,
          type: 'EMPLOYEE-QR-ID'
        });
        QRCode.toDataURL(qrData, { width: 180, margin: 2 }, (err, url) => {
          if (!err) setEmployeeQrCode(url);
        });
      }
    }
  }, [role, pegawai, username]);

  // Generate QR Code dynamically for Admin's QR modal
  useEffect(() => {
    if (activeQrEmployee) {
      const qrData = JSON.stringify({
        id: activeQrEmployee.id,
        nama: activeQrEmployee.nama,
        jabatan: activeQrEmployee.jabatan,
        divisi: activeQrEmployee.nama_divisi || 'Tanpa Divisi',
        type: 'EMPLOYEE-QR-ID'
      });
      QRCode.toDataURL(qrData, { width: 240, margin: 2 }, (err, url) => {
        if (!err) setAdminQrSrc(url);
      });
    } else {
      setAdminQrSrc('');
    }
  }, [activeQrEmployee]);

  // Load ketidakhadiran data when date or role changes
  useEffect(() => {
    if (role === 'admin') {
      getKetidakhadiran();
    }
  }, [ketidakhadiranDate, role]);

  // Auto-refresh ketidakhadiran data every day at midnight
  useEffect(() => {
    if (role !== 'admin') return;

    // Function to check if it's a new day and refresh
    const checkAndRefreshDaily = () => {
      const today = getLocalDateStr();
      
      // If the date has changed, update it
      if (ketidakhadiranDate !== today) {
        setKetidakhadiranDate(today);
        // getKetidakhadiran will be called by the useEffect above due to ketidakhadiranDate change
      }
    };

    // Check every minute if date has changed
    const intervalId = setInterval(checkAndRefreshDaily, 60000); // Check every minute

    // Also check immediately on mount
    checkAndRefreshDaily();

    return () => clearInterval(intervalId);
  }, [role]);

  // Auto-refresh absensi data setiap 30 detik (agar jam keluar karyawan terupdate otomatis)
  useEffect(() => {
    if (role !== 'admin' || !token) return;

    const intervalId = setInterval(() => {
      getAbsensi();
    }, 30000); // refresh setiap 30 detik

    return () => clearInterval(intervalId);
  }, [role, token]);

  // Initialize User Scanner
  useEffect(() => {
    if (!isScannerOpen) return;

    const initUserScanner = async () => {
      try {
        const scanner = new Html5QrcodeScanner(
          "user-scanner",
          { 
            fps: 10, 
            qrbox: 250,
            disableFlip: false
          },
          false
        );

        scanner.render(
          (decodedText) => {
            handleUserQrScan(decodedText);
          },
          (error) => {
            console.log(error);
          }
        );

        window.userScanner = scanner;
      } catch (err) {
        console.error('Error initializing user scanner:', err);
      }
    };

    initUserScanner();

    return () => {
      console.log(' Cleaning up user scanner...');
      
      // Stop video tracks first
      const videos = document.querySelectorAll('video');
      videos.forEach((video) => {
        try {
          if (video.srcObject) {
            const tracks = video.srcObject.getTracks();
            tracks.forEach((track) => {
              track.stop();
              console.log(' Video track stopped:', track.kind);
            });
            video.srcObject = null;
            video.style.display = 'none';
          }
        } catch (err) {
          console.error('Error stopping video track:', err);
        }
      });

      // Then stop and clear scanner
      if (window.userScanner) {
        try {
          window.userScanner.clear().then(() => {
            console.log(' User scanner cleared');
          }).catch((err) => {
            console.error('Error clearing user scanner:', err);
          });
        } catch (err) {
          console.error('Error in userScanner clear:', err);
        }
        window.userScanner = null;
      }
    };
  }, [isScannerOpen]);

  // Initialize Admin Scanner
  useEffect(() => {
    if (!isQrScannerOpen) return;

    const initAdminScanner = async () => {
      try {
        const scanner = new Html5QrcodeScanner(
          "admin-scanner",
          { 
            fps: 10, 
            qrbox: 250,
            disableFlip: false
          },
          false
        );

        scanner.render(
          (decodedText) => {
            handleQrCodeScan(decodedText);
          },
          (error) => {
            console.log(error);
          }
        );

        window.adminScanner = scanner;
      } catch (err) {
        console.error('Error initializing admin scanner:', err);
      }
    };

    initAdminScanner();

    return () => {
      console.log(' Cleaning up admin scanner...');
      
      // Stop video tracks first
      const videos = document.querySelectorAll('video');
      videos.forEach((video) => {
        try {
          if (video.srcObject) {
            const tracks = video.srcObject.getTracks();
            tracks.forEach((track) => {
              track.stop();
              console.log(' Video track stopped:', track.kind);
            });
            video.srcObject = null;
            video.style.display = 'none';
          }
        } catch (err) {
          console.error('Error stopping video track:', err);
        }
      });

      // Then stop and clear scanner
      if (window.adminScanner) {
        try {
          window.adminScanner.clear().then(() => {
            console.log(' Admin scanner cleared');
          }).catch((err) => {
            console.error('Error clearing admin scanner:', err);
          });
        } catch (err) {
          console.error('Error in adminScanner clear:', err);
        }
        window.adminScanner = null;
      }
    };
  }, [isQrScannerOpen]);

  // ==========================================
  // CAMERA STREAM CLEANUP
  // ==========================================
  function stopAllCameraStreams() {
    try {
      // Stop all video elements
      document.querySelectorAll('video').forEach((video) => {
        if (video.srcObject) {
          const tracks = video.srcObject.getTracks();
          tracks.forEach((track) => {
            track.stop();
          });
          video.srcObject = null;
        }
        video.pause();
      });
      
      // Stop html5-qrcode scanner if active
      if (window.userScanner) {
        window.userScanner.clear().catch(() => {});
        window.userScanner = null;
      }
      if (window.adminScanner) {
        window.adminScanner.clear().catch(() => {});
        window.adminScanner = null;
      }
    } catch (err) {
      console.error('Error stopping camera streams:', err);
    }
  }

  // Stop camera when office scanner closes
  useEffect(() => {
    if (!isScannerOpen) {
      const timer = setTimeout(() => {
        stopAllCameraStreams();
      }, 50);
      return () => clearTimeout(timer);
    }
  }, [isScannerOpen]);

  // Stop camera when QR admin scanner closes
  useEffect(() => {
    if (!isQrScannerOpen) {
      const timer = setTimeout(() => {
        stopAllCameraStreams();
      }, 50);
      return () => clearTimeout(timer);
    }
  }, [isQrScannerOpen]);

  async function loadAllData() {
    try {
      await Promise.all([getPegawai(), getDivisi(), getAbsensi(), getCuti(), getWorkSettings()]);
    } catch (err) {
      console.error('Error loading initial data:', err);
    }
  }

  // ==========================================
  // WORK HOURS SETTINGS
  // ==========================================
  async function getWorkSettings() {
    try {
      const res = await axios.get('http://localhost:5000/settings');
      // Normalize time from DB format "HH:MM:SS" to "HH:MM" for consistent string comparison
      const normalizeTime = (t) => (t ? String(t).slice(0, 5) : t);
      const data = res.data;
      const normalized = {
        ...data,
        jam_masuk_awal: normalizeTime(data.jam_masuk_awal),
        jam_masuk_akhir: normalizeTime(data.jam_masuk_akhir),
        jam_keluar_awal: normalizeTime(data.jam_keluar_awal),
        jam_keluar_akhir: normalizeTime(data.jam_keluar_akhir),
      };
      setWorkSettings(normalized);
      setTempWorkSettings(normalized);
    } catch (err) {
      console.error('Error fetching work settings:', err);
      // Set default if error
      const defaults = {
        jam_masuk_awal: '07:00',
        jam_masuk_akhir: '09:00',
        jam_keluar_awal: '16:00',
        jam_keluar_akhir: '17:00'
      };
      setWorkSettings(defaults);
      setTempWorkSettings(defaults);
    }
  }

  async function updateWorkSettings() {
    try {
      // Strip seconds from time values (convert HH:MM:SS to HH:MM)
      const cleanedSettings = {
        jam_masuk_awal: tempWorkSettings.jam_masuk_awal?.split(':').slice(0, 2).join(':') || tempWorkSettings.jam_masuk_awal,
        jam_masuk_akhir: tempWorkSettings.jam_masuk_akhir?.split(':').slice(0, 2).join(':') || tempWorkSettings.jam_masuk_akhir,
        jam_keluar_awal: tempWorkSettings.jam_keluar_awal?.split(':').slice(0, 2).join(':') || tempWorkSettings.jam_keluar_awal,
        jam_keluar_akhir: tempWorkSettings.jam_keluar_akhir?.split(':').slice(0, 2).join(':') || tempWorkSettings.jam_keluar_akhir
      };
      
      const res = await axios.put(
        'http://localhost:5000/settings',
        cleanedSettings,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setWorkSettings(res.data.settings);
      setEditingWorkSettings(false);
      showToast('Pengaturan jam kerja berhasil diperbarui!', 'success');
    } catch (err) {
      console.error('Error updating work settings:', err);
      showToast(err.response?.data?.message || 'Gagal memperbarui pengaturan jam kerja', 'error');
    }
  }

  // ==========================================
  // AUTHENTICATION: LOGIN & LOGOUT
  // ==========================================
  async function login() {
    if (!username || !password) {
      showToast('Username dan Password tidak boleh kosong!', 'error');
      return;
    }
    try {
      console.log(' Login attempt:', { username, passwordLength: password.length });
      
      const res = await axios.post('http://localhost:5000/login', {
        username,
        password
      });

      console.log(' Login response:', res.data);
      
      const tokenVal = res.data.token;
      const roleVal = res.data.role || (username.toLowerCase() === 'admin' ? 'admin' : 'user');

      localStorage.setItem('token', tokenVal);
      localStorage.setItem('role', roleVal);
      localStorage.setItem('username', username);

      setToken(tokenVal);
      setRole(roleVal);
      showToast(`Login berhasil! Selamat datang, ${username}.`, 'success');
    } catch (err) {
      console.error(' Login error:', err.response?.data || err.message);
      showToast(err.response?.data?.message || 'Login gagal. Username atau password salah.', 'error');
    }
  }

  // LOGOUT
  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    localStorage.removeItem('username');
    sessionStorage.removeItem('quotaAlertShown');
    setToken('');
    setRole('');
    setUsername('');
    setPassword('');
    setCurrentEmployee(null);
    setEmployeeQrCode('');
    setIsScannerOpen(false);
    showToast('Berhasil keluar dari sesi.', 'success');
  }

  // ==========================================
  // PEGAWAI CRUD (ADMIN)
  // ==========================================
  async function getPegawai() {
    try {
      const res = await axios.get('http://localhost:5000/pegawai', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setPegawai(res.data.data || []);
    } catch (err) {
      console.error(err);
      if (err.response && err.response.status === 403) logout();
    }
  }

  async function checkQrEligibility() {
    setQrEligibility((prev) => ({ ...prev, loading: true }));
    try {
      const res = await axios.get('http://localhost:5000/check-qr-eligibility', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setQrEligibility({
        loading: false,
        eligible: res.data.eligible,
        reason: res.data.reason,
        date: res.data.date
      });
    } catch (err) {
      console.error(err);
      setQrEligibility({
        loading: false,
        eligible: false,
        reason: 'Gagal memverifikasi status kelayakan hari kerja.',
        date: ''
      });
    }
  }

  async function generateOfficeQr() {
    try {
      const res = await axios.get('http://localhost:5000/generate-office-qr', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOfficeQrCode(res.data.qrImage);
      showToast('QR Code absensi hari ini berhasil dibuat!', 'success');
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal membuat QR Code.', 'error');
    }
  }

  async function hapusPegawai(id) {
    showCustomConfirm(
      'Apakah Anda yakin ingin menghapus data pegawai ini beserta akun loginnya?',
      async () => {
        try {
          await axios.delete(`http://localhost:5000/pegawai/${id}`, {
            headers: { Authorization: `Bearer ${token}` }
          });
          showToast('Data pegawai dan akun berhasil dihapus.', 'success');
          getPegawai();
        } catch (err) {
          console.error('hapusPegawai error:', err);
          if (err.response) {
            const status = err.response.status;
            const msg = err.response.data?.message || '';
            if (status === 403) {
              showToast('Sesi Anda telah berakhir. Silakan login ulang.', 'error');
              setTimeout(() => logout(), 1500);
            } else if (status === 500) {
              showToast('Gagal menghapus pegawai: ' + msg, 'error');
            } else {
              showToast(msg || 'Gagal menghapus pegawai.', 'error');
            }
          } else if (err.request) {
            showToast('Tidak dapat terhubung ke server. Pastikan backend berjalan.', 'error');
          } else {
            showToast('Gagal menghapus pegawai.', 'error');
          }
        }
      },
      'Hapus Pegawai'
    );
  }

  function handleFotoChange(e) {
    const file = e.target.files[0];
    if (!file) return;

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      showToast('Ukuran foto terlalu besar (max 5MB)', 'error');
      return;
    }

    // Check file type
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      showToast('Format foto harus JPG, PNG, atau WebP', 'error');
      return;
    }

    setIsUploadingFoto(true);
    const reader = new FileReader();
    reader.onload = (event) => {
      setEditFoto(event.target.result);
      setIsUploadingFoto(false);
      showToast('Foto berhasil dipilih', 'success');
    };
    reader.onerror = () => {
      setIsUploadingFoto(false);
      showToast('Gagal membaca file foto', 'error');
    };
    reader.readAsDataURL(file);
  }

  async function editPegawai() {
    if (!editingEmployee) return;

    if (!editJabatan && !editDivisiId && !editFoto) {
      showToast('Tidak ada perubahan data', 'warning');
      return;
    }

    try {
      const updateData = {
        nama: editingEmployee.nama,
        jabatan: editJabatan || editingEmployee.jabatan,
        divisi_id: editDivisiId || editingEmployee.divisi_id || null
      };

      if (editFoto) {
        updateData.foto = editFoto;
      }

      await axios.put(`http://localhost:5000/pegawai/${editingEmployee.id}`, updateData, {
        headers: { Authorization: `Bearer ${token}` }
      });

      showToast('Data pegawai berhasil diperbarui', 'success');
      setEditingEmployee(null);
      setEditJabatan('');
      setEditDivisiId('');
      setEditFoto('');
      getPegawai();
      setActiveDetailEmployee(null);
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal update pegawai', 'error');
    }
  }

  async function ubahPassword() {
    if (!newPassword) {
      showToast('Password baru wajib diisi!', 'error');
      return;
    }
    try {
      await axios.post(
        'http://localhost:5000/change-password',
        { old_password: oldPassword, new_password: newPassword },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast('Password berhasil diperbarui!', 'success');
      setOldPassword('');
      setNewPassword('');
      setIsChangePasswordOpen(false);
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengubah password.', 'error');
    }
  }

  // ==========================================
  // USER SETTINGS (CHANGE PROFILE & PASSWORD)
  // ==========================================
  async function updateUserProfile() {
    if (!settingsUserFoto) {
      showToast('Pilih foto profil terlebih dahulu!', 'error');
      return;
    }
    try {
      await axios.put(
        'http://localhost:5000/user/profile',
        { foto: settingsUserFoto },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      // Update currentEmployee state immediately with new photo
      setCurrentEmployee((prev) => ({ ...prev, foto: settingsUserFoto }));
      
      // Update pegawai array to ensure admin sees updated photo
      setPegawai((prevPegawai) =>
        prevPegawai.map((p) =>
          p.nama.toLowerCase() === (currentEmployee?.nama || localStorage.getItem('username')).toLowerCase()
            ? { ...p, foto: settingsUserFoto }
            : p
        )
      );
      
      showToast('Foto profil berhasil diperbarui!', 'success');
      setSettingsUserFoto('');
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengubah foto profil.', 'error');
    }
  }

  async function updateUserPassword() {
    if (!settingsOldPassword) {
      showToast('Password lama wajib diisi!', 'error');
      return;
    }
    if (!settingsNewPassword) {
      showToast('Password baru wajib diisi!', 'error');
      return;
    }
    if (settingsNewPassword !== settingsConfirmPassword) {
      showToast('Password baru dan konfirmasi password tidak cocok!', 'error');
      return;
    }
    if (settingsNewPassword.length < 6) {
      showToast('Password baru minimal 6 karakter!', 'error');
      return;
    }
    try {
      await axios.post(
        'http://localhost:5000/change-password',
        { old_password: settingsOldPassword, new_password: settingsNewPassword },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast('Password berhasil diperbarui!', 'success');
      setSettingsOldPassword('');
      setSettingsNewPassword('');
      setSettingsConfirmPassword('');
      setShowPasswordFields(false);
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengubah password.', 'error');
    }
  }

  function handleSettingsFotoChange(e) {
    const file = e.target.files[0];
    if (!file) return;

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      showToast('Ukuran foto terlalu besar (max 5MB)', 'error');
      return;
    }

    // Check file type
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      showToast('Format foto harus JPG, PNG, atau WebP', 'error');
      return;
    }

    setIsUploadingUserFoto(true);
    const reader = new FileReader();
    reader.onload = (event) => {
      setSettingsUserFoto(event.target.result);
      setIsUploadingUserFoto(false);
      showToast('Foto berhasil dipilih', 'success');
    };
    reader.onerror = () => {
      setIsUploadingUserFoto(false);
      showToast('Gagal membaca file foto', 'error');
    };
    reader.readAsDataURL(file);
  }

  // ==========================================
  // DIVISI CRUD (ADMIN)
  // ==========================================
  async function getDivisi() {
    try {
      const res = await axios.get('http://localhost:5000/divisi', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setDivisi(res.data.data || []);
    } catch (err) {
      console.error(err);
    }
  }

  async function tambahDivisi() {
    if (!namaDivisi) {
      showToast('Nama divisi wajib diisi!', 'error');
      return;
    }
    try {
      await axios.post(
        'http://localhost:5000/divisi',
        { nama_divisi: namaDivisi },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast('Divisi baru berhasil disimpan!', 'success');
      setNamaDivisi('');
      getDivisi();
    } catch (err) {
      console.error(err);
      showToast('Gagal menyimpan divisi.', 'error');
    }
  }

  // ==========================================
  // ABSENSI CRUD (ADMIN & USER)
  // ==========================================
  async function getAbsensi() {
    try {
      const res = await axios.get('http://localhost:5000/absensi', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setAbsensi(res.data.data || []);
    } catch (err) {
      console.error(err);
    }
  }

  async function tambahAbsensi() {
    if (!absensiPegawaiId) {
      showToast('Pilih pegawai terlebih dahulu!', 'error');
      return;
    }
    try {
      const res = await axios.post(
        'http://localhost:5000/absensi',
        {
          pegawai_id: absensiPegawaiId,
          tanggal: absensiTanggal,
          jam_masuk: absensiJamMasuk,
          jam_keluar: absensiJamKeluar,
          status: absensiStatus
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      if (res.data.limitExceeded) {
        showToast('Presensi dicatat sebagai ALPA karena melebihi batas 7 hari.', 'error');
        showCustomAlert('⚠️ PERINGATAN KARYAWAN:\n\nJatah Izin & Sakit (7 hari) pegawai ini telah habis!\nPresensi dicatat otomatis sebagai ALPA.', 'Peringatan Kelompok 2');
      } else {
        showToast('Absensi berhasil dicatat!', 'success');
      }
      setAbsensiPegawaiId('');
      getAbsensi();
    } catch (err) {
      console.error(err);
      showToast('Gagal mencatat absensi.', 'error');
    }
  }

  async function getKetidakhadiran() {
    try {
      const res = await axios.get(`http://localhost:5000/ketidakhadiran?tanggal=${ketidakhadiranDate}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = res.data;
      if (data.is_holiday) {
        setHolidayInfo({
          is_holiday: true,
          holiday_type: data.holiday_type,
          holiday_name: data.holiday_name,
          keterangan: data.keterangan
        });
        setKetidakhadiran([]);
      } else {
        setHolidayInfo(null);
        setKetidakhadiran(data.data || []);
      }
    } catch (err) {
      console.error(err);
      showToast('Gagal mengambil data ketidakhadiran.', 'error');
    }
  }

  // ==========================================
  // CUTI TAMBAHAN ACTIONS (ADMIN & USER)
  // ==========================================
  async function getCuti() {
    try {
      const res = await axios.get('http://localhost:5000/cuti', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setCuti(res.data.data || []);
    } catch (err) {
      console.error('Error fetching leaves:', err);
    }
  }

  // ==========================================
  // CUTI NOTIFICATION (DITOLAK/DITERIMA) - USER
  // ==========================================
  async function getCutiNotifs() {
    if (!token || role !== 'user') return;
    setIsCutiNotifLoading(true);
    try {
      const res = await axios.get('http://localhost:5000/cuti/notif', {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = res.data?.data || res.data?.notifs || res.data?.cutiNotifs || [];
      setCutiNotifs(Array.isArray(data) ? data : []);

      // Show modal immediately if exists
      if (Array.isArray(data) && data.length > 0) {
        setCutiNotifModal(data[0]);
      } else {
        setCutiNotifModal(null);
      }
    } catch (err) {
      console.error('Error fetching cuti notifications:', err);
    } finally {
      setIsCutiNotifLoading(false);
    }
  }

  async function markCutiNotifAsRead(cutiIds = []) {
    if (!token || role !== 'user') return;
    if (!Array.isArray(cutiIds) || cutiIds.length === 0) return;
    setIsCutiNotifMarkingRead(true);
    try {
      await axios.post(
        'http://localhost:5000/cuti/notif/read',
        { cuti_ids: cutiIds },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      // Clear from UI
      setCutiNotifs((prev) => prev.filter((x) => !cutiIds.includes(x.id)));
      setCutiNotifModal(null);
    } catch (err) {
      console.error('Error marking cuti notifications as read:', err);
    } finally {
      setIsCutiNotifMarkingRead(false);
    }
  }


  const getSisaKuotaBiasa = () => {
    if (!currentEmployee) return 7;
    const myLogs = absensi.filter((a) => a.nama.toLowerCase() === currentEmployee.nama.toLowerCase());
    // Combine Sakit and Izin into single Izin count
    const countIzin = myLogs.filter((l) => l.status === 'Izin' || l.status === 'Sakit').length;

    const myCuti = cuti.filter((c) => c.nama.toLowerCase() === currentEmployee.nama.toLowerCase());
    const approvedCutiDays = myCuti
      .filter((c) => c.status === 'Disetujui')
      .reduce((sum, current) => sum + parseInt(current.durasi_hari), 0);

    const totalLeaveCount = countIzin;
    const quotaLimit = 7 + approvedCutiDays;
    return quotaLimit - totalLeaveCount;
  };

  async function submitCutiBiasa() {
    if (!currentEmployee) {
      showToast('Profil Pegawai Anda tidak ditemukan!', 'error');
      return;
    }
    if (!biasaTanggalMulai || !biasaTanggalSelesai) {
      showToast('Tanggal mulai dan selesai harus diisi!', 'error');
      return;
    }
    // Tolak tanggal yang sudah lewat
    if (biasaTanggalMulai < todayStr) {
      showToast('❌ Tidak bisa mengajukan cuti untuk tanggal yang sudah lewat! Pilih tanggal mulai dari hari ini.', 'error');
      return;
    }
    const start = new Date(biasaTanggalMulai);
    const end = new Date(biasaTanggalSelesai);
    const duration = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
    if (duration <= 0) {
      showToast('Tanggal selesai tidak valid!', 'error');
      return;
    }

    const sisa = getSisaKuotaBiasa();
    if (duration > sisa) {
      showCustomAlert('❌ Jatah Habis!\n\nTidak bisa mengirim pengajuan karena sisa kuota tidak mencukupi.', 'Kuota Habis');
      return;
    }

    try {
      await axios.post(
        'http://localhost:5000/absensi',
        {
          pegawai_id: currentEmployee.id,
          tanggal_mulai: biasaTanggalMulai,
          tanggal_selesai: biasaTanggalSelesai,
          status: `Pending ${biasaStatus}`,
          alasan: biasaAlasan,
          foto_bukti: biasaFotoBukti
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast('Pengajuan Cuti Biasa berhasil dikirim!', 'success');
      setBiasaAlasan('');
      setBiasaFotoBukti('');
      loadAllData();
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengirimkan pengajuan cuti biasa.', 'error');
    }
  }

  async function submitCutiTambahan() {
    if (!currentEmployee) {
      showToast('Profil Pegawai Anda tidak ditemukan!', 'error');
      return;
    }
    if (!tambahanTanggalMulai || !tambahanTanggalSelesai) {
      showToast('Tanggal mulai dan selesai harus diisi!', 'error');
      return;
    }
    // Tolak tanggal yang sudah lewat
    if (tambahanTanggalMulai < todayStr) {
      showToast('❌ Tidak bisa mengajukan cuti tambahan untuk tanggal yang sudah lewat! Pilih tanggal mulai dari hari ini.', 'error');
      return;
    }
    const start = new Date(tambahanTanggalMulai);
    const end = new Date(tambahanTanggalSelesai);
    const duration = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
    if (duration <= 0) {
      showToast('Tanggal selesai tidak valid!', 'error');
      return;
    }

    if (tambahanKeperluan === 'Izin/Sakit Lanjutan' && duration > 5) {
      showCustomAlert('❌ Batas Cuti Tambahan Terlewati!\n\nKategori Izin/Sakit Lanjutan maksimal 5 hari.', 'Batas Terlewati');
      return;
    }

    try {
      await axios.post(
        'http://localhost:5000/cuti',
        {
          pegawai_id: currentEmployee.id,
          tanggal_mulai: tambahanTanggalMulai,
          tanggal_selesai: tambahanTanggalSelesai,
          keperluan: tambahanKeperluan,
          alasan: tambahanAlasan,
          foto_bukti: tambahanFotoBukti
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast('Pengajuan Cuti Tambahan berhasil dikirim!', 'success');
      setTambahanAlasan('');
      setTambahanFotoBukti('');
      loadAllData();
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengirimkan pengajuan cuti tambahan.', 'error');
    }
  }

  async function updateStatusCuti(id, status) {
    try {
      await axios.put(
        `http://localhost:5000/cuti/${id}`,
        { status },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(`Pengajuan cuti telah ${status}!`, 'success');
      getCuti();
      getAbsensi(); // Refresh attendance because quota might have updated
    } catch (err) {
      console.error(err);
      showToast('Gagal mengupdate status cuti.', 'error');
    }
  }

  // ==========================================
  // USER PRESENSI PROCESSORS
  // ==========================================
  async function handleUserQrScan(text) {
    if (!text || !isScannerOpen) return; // Prevent multiple scans
    
    //  Immediately stop scanner to prevent duplicate scans
    try {
      if (window.userScanner) {
        await window.userScanner.clear();
        window.userScanner = null;
      }
      // Stop all video streams
      document.querySelectorAll('video').forEach((video) => {
        if (video.srcObject) {
          const tracks = video.srcObject.getTracks();
          tracks.forEach((track) => track.stop());
          video.srcObject = null;
        }
      });
    } catch (err) {
      console.error('Error stopping scanner:', err);
    }
    
    const todayStr = new Date().toLocaleString("sv", { timeZone: "Asia/Jakarta" }).split(" ")[0];
    const expectedOfficeQr = `OFFICE-PRESENSI-QR-${todayStr}`;

    if (text === expectedOfficeQr || text === 'OFFICE-PRESENSI-QR' || text === 'ABSENSI-SEC') {
      await submitSelfAttendance();
    } else {
      showToast('QR Code tidak valid atau sudah kedaluwarsa!', 'error');
      setIsScannerOpen(false);
    }
  }

  async function executeSelfAttendance(status, curDate, curTime) {
    try {
      const res = await axios.post(
        'http://localhost:5000/absensi',
        {
          pegawai_id: currentEmployee.id,
          tanggal: curDate,
          jam_masuk: curTime,
          jam_keluar: null,
          status: status
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      if (res.data.dailyLimitExceeded) {
        const msg = res.data.message || 'Anda sudah melakukan absensi hari ini.';
        showToast(msg, 'warning');
        
        // Detect apakah error karena time (checkout) atau sudah tercatat
        const isCheckoutTimeError = msg.includes('belum dimulai') || msg.includes('berakhir');
        const isAlreadyCheckedOut = msg.includes('sudah absen pulang');
        
        let alertTitle = 'Absensi Tidak Dapat Dilakukan';
        let alertBody = `ℹ️ INFORMASI\n\n${msg}`;
        
        if (isCheckoutTimeError) {
          alertTitle = 'Waktu Absen Pulang Terbatas';
          alertBody = `⏰ BATASAN WAKTU\n\n${msg}\n\nSilakan lakukan absen pulang sesuai dengan jam yang ditentukan oleh Admin.`;
        } else if (isAlreadyCheckedOut) {
          alertTitle = 'Absen Sudah Tercatat';
          alertBody = `✅ INFORMASI\n\n${msg}\n\nAnda tidak dapat melakukan absen pulang lebih dari sekali dalam sehari.`;
        } else {
          alertBody = `ℹ️ INFORMASI\n\n${msg}\n\nSilakan lakukan absensi sesuai dengan jam kerja yang ditentukan oleh Admin.`;
        }
        
        showCustomAlert(alertBody, alertTitle);
      } else if (res.data.limitExceeded) {
        showToast('Presensi dicatat sebagai ALPA karena batas 7 hari habis.', 'error');
        showCustomAlert('⚠️ PERINGATAN KARYAWAN\n\nJatah Sakit & Izin (7 hari) Anda telah habis!\nPresensi hari ini otomatis tercatat sebagai ALPA.\n\nSilakan ajukan "Cuti Tambahan" di tab pengajuan dan tunggu persetujuan (acc) Admin.', 'Peringatan Jatah Habis');
      } else {
        // Deteksi check-in vs check-out dari pesan response backend
        const isCheckout = res.data.message && res.data.message.toLowerCase().includes('check-out');
        if (isCheckout) {
          showToast('✅ Check-Out Berhasil! Jam Pulang Tercatat.', 'success');
        } else {
          showToast('✅ Check-In Berhasil! Jam Masuk Tercatat.', 'success');
        }
      }
      // Refresh data absensi setelah scan
      await getAbsensi();
    } catch (err) {
      console.error(err);
      showToast('Presensi gagal. Terjadi kesalahan.', 'error');
    }
  }

  async function submitSelfAttendance(status = 'Hadir') {
    if (!currentEmployee) {
      showToast('Profil Pegawai Anda belum ditautkan ke sistem!', 'error');
      setIsScannerOpen(false);
      return;
    }

    const now = new Date();
    const curDate = getLocalDateStr(now);
    const curTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    
    // Check if check-in time has not started yet
    if (curTime < workSettings.jam_masuk_awal) {
      setIsScannerOpen(false); // Stop scanner
      showCustomAlert(`⚠️ PERINGATAN\n\nAbsensi gagal dilakukan.\nJam absen belum dimulai.\n\nJam kerja: ${workSettings.jam_masuk_awal} - ${workSettings.jam_keluar_akhir}`, 'Absensi Belum Dimulai');
      return;
    }

    // Check if outside work hours and show warning
    const isOutsideWorkHours = curTime > workSettings.jam_keluar_akhir;
    
    if (isOutsideWorkHours) {
      setIsScannerOpen(false); // Stop scanner
      setOutsideHoursData({ status, curDate, curTime });
      setShowOutsideHoursModal(true);
    } else {
      await executeSelfAttendance(status, curDate, curTime);
      setIsScannerOpen(false);
    }
  }

  // Submit pengajuan Izin/Sakit dengan keterangan dan foto (status Pending) - support date range
  async function submitIzinSakit() {
    if (!currentEmployee) {
      showToast('Profil Pegawai Anda belum ditautkan ke sistem!', 'error');
      return;
    }
    if (!izinSakitAlasan.trim()) {
      showToast('Keterangan/alasan wajib diisi!', 'error');
      return;
    }
    const now = new Date();
    const curDate = getLocalDateStr(now);
    const mulai = izinSakitTanggalMulai || curDate;
    const selesai = izinSakitTanggalSelesai || curDate;
    if (selesai < mulai) {
      showToast('Tanggal selesai tidak boleh sebelum tanggal mulai!', 'error');
      return;
    }
    const start = new Date(mulai);
    const end = new Date(selesai);
    const durasi = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
    const pendingStatus = `Pending ${izinSakitModal.type}`;

    try {
      await axios.post(
        'http://localhost:5000/absensi',
        {
          pegawai_id: currentEmployee.id,
          tanggal: mulai,
          tanggal_mulai: mulai,
          tanggal_selesai: selesai,
          jam_masuk: '00:00',
          jam_keluar: '00:00',
          status: pendingStatus,
          alasan: izinSakitAlasan,
          foto_bukti: izinSakitFoto || null
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      showToast(`Pengajuan ${izinSakitModal.type} (${durasi} hari) berhasil dikirim! Menunggu persetujuan Admin.`, 'success');
      setIzinSakitModal({ show: false, type: '' });
      setIzinSakitAlasan('');
      setIzinSakitFoto('');
      setIzinSakitTanggalMulai('');
      setIzinSakitTanggalSelesai('');
      getAbsensi();
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal mengirim pengajuan.', 'error');
    }
  }

  // Admin: Buka modal konfirmasi ACC/Tolak pengajuan Izin/Sakit
  function openApprovalModal(type, data) {
    setApprovalModal({ type, data });
  }

  // Admin: Approve/Reject pengajuan Izin/Sakit (group - semua record dengan alasan & pegawai yang sama)
  async function approveRejectAbsensi(pegawaiId, alasan, currentStatus, action) {
    try {
      let newStatus;
      if (action === 'approve') {
        newStatus = currentStatus.replace('Pending ', '');
      } else {
        newStatus = 'Ditolak';
      }

      // Group approve: update semua record pending dengan pegawai_id & alasan yang sama
      await axios.put(
        `http://localhost:5000/absensi/group-approve`,
        { pegawai_id: pegawaiId, alasan, old_status: currentStatus, new_status: newStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setApprovalModal(null);
      showToast(`Semua pengajuan berhasil ${action === 'approve' ? 'disetujui' : 'ditolak'}!`, action === 'approve' ? 'success' : 'error');
      getAbsensi();
    } catch (err) {
      console.error(err);
      showToast('Gagal mengubah status pengajuan.', 'error');
    }
  }

  // Admin: Approve cuti tambahan (satu klik, auto buat absensi harian)
  async function approveRejectCuti(id, action) {
    try {
      const newStatus = action === 'approve' ? 'Disetujui' : 'Ditolak';
      await axios.put(
        `http://localhost:5000/cuti/${id}`,
        { status: newStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setApprovalModal(null);
      showToast(`Cuti tambahan berhasil ${action === 'approve' ? 'disetujui' : 'ditolak'}!`, action === 'approve' ? 'success' : 'error');
      getCuti();
      getAbsensi();
    } catch (err) {
      console.error(err);
      showToast('Gagal mengubah status cuti.', 'error');
    }
  }

  // Toggle checkbox untuk cuti tertentu
  function toggleCutiCheckbox(cutiId) {
    const newSet = new Set(selectedCutiIds);
    if (newSet.has(cutiId)) {
      newSet.delete(cutiId);
    } else {
      newSet.add(cutiId);
    }
    setSelectedCutiIds(newSet);
  }

  // Select all pending cuti
  function toggleSelectAllCuti(filteredCuti) {
    const pendingIds = new Set(filteredCuti.filter(c => c.status === 'Pending').map(c => c.id));
    if (selectedCutiIds.size === pendingIds.size && [...selectedCutiIds].every(id => pendingIds.has(id))) {
      setSelectedCutiIds(new Set());
    } else {
      setSelectedCutiIds(pendingIds);
    }
  }

  // Approve multiple cuti sekaligus
  async function approveMultipleCuti() {
    if (selectedCutiIds.size === 0) {
      showToast('Pilih minimal 1 pengajuan cuti!', 'warning');
      return;
    }

    if (!window.confirm(`Yakin ACC ${selectedCutiIds.size} pengajuan cuti sekaligus?`)) {
      return;
    }

    try {
      const ids = Array.from(selectedCutiIds);
      const response = await axios.put(
        'http://localhost:5000/cuti/batch-approve',
        { ids },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      setSelectedCutiIds(new Set());
      showToast(`${response.data.successCount} pengajuan cuti berhasil disetujui!`, 'success');
      getCuti();
      getAbsensi();
    } catch (err) {
      console.error(err);
      showToast('Terjadi kesalahan saat approve multiple.', 'error');
    }
  }

  // ==========================================
  // QR CODE MANAGEMENT (ADMIN & USER)
  // ==========================================
  async function generateQrCodeForUser() {
    if (!selectedUserForQr || !qrTanggalBerlaku) {
      showToast('Pilih pegawai dan tanggal berlaku!', 'error');
      return;
    }

    try {
      const res = await axios.post(
        'http://localhost:5000/qr-code/generate',
        {
          pegawai_id: selectedUserForQr,
          tanggal_berlaku: qrTanggalBerlaku
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setGeneratedQrCode(res.data.qr_code);
      showToast(`QR Code untuk ${res.data.pegawai_nama} berhasil dibuat!`, 'success');
      getQrCodeList();
      setSelectedUserForQr('');
      setQrPegawaiSearch('');
      setQrTanggalBerlaku(getLocalDateStr());
    } catch (err) {
      console.error(err);
      showToast(err.response?.data?.message || 'Gagal membuat QR Code', 'error');
    }
  }

  async function getQrCodeList() {
    try {
      console.log(' Fetching QR code list...');
      const res = await axios.get('http://localhost:5000/qr-code/list', {
        headers: { Authorization: `Bearer ${token}` }
      });
      console.log(' QR code list loaded:', res.data.data);
      setQrCodeList(res.data.data || []);
    } catch (err) {
      console.error(' Error fetching QR codes:', err.message);
      setQrCodeList([]); // Set empty list on error
      showToast('Gagal load QR code list', 'error');
    }
  }

  async function deleteQrCode(id) {
    showCustomConfirm('Apakah Anda yakin ingin menghapus QR Code ini?', async () => {
      try {
        await axios.delete(`http://localhost:5000/qr-code/${id}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        showToast('QR Code berhasil dihapus', 'success');
        getQrCodeList();
      } catch (err) {
        console.error(err);
        showToast(err.response?.data?.message || 'Gagal menghapus QR Code', 'error');
      }
    }, 'Hapus QR Code');
  }

  async function handleQrCodeScan(text) {
    if (!text || !isQrScannerOpen) return; // Prevent multiple scans

    //  Immediately stop scanner to prevent duplicate scans
    try {
      if (window.adminScanner) {
        await window.adminScanner.clear();
        window.adminScanner = null;
      }
      // Stop all video streams
      document.querySelectorAll('video').forEach((video) => {
        if (video.srcObject) {
          const tracks = video.srcObject.getTracks();
          tracks.forEach((track) => track.stop());
          video.srcObject = null;
        }
      });
    } catch (err) {
      console.error('Error stopping admin scanner:', err);
    }

    try {
      // Try to parse as JSON (Employee ID Card QR)
      let qrData = null;
      try {
        qrData = JSON.parse(text);
      } catch (e) {
        // Not JSON, treat as regular QR code
      }

      // If it's an employee ID card QR and admin is scanning for checkout
      if (qrData && qrData.type === 'EMPLOYEE-QR-ID' && role === 'admin' && activeTab === 'scan-checkout') {
        const res = await axios.post(
          'http://localhost:5000/checkout',
          { pegawai_id: qrData.id },
          { headers: { Authorization: `Bearer ${token}` } }
        );

        showToast(res.data.message, 'success');
        showCustomAlert(`✅ CHECKOUT BERHASIL\n\nNama: ${res.data.pegawai_nama}\nJam Masuk: ${res.data.jam_masuk}\nJam Pulang: ${res.data.jam_keluar}\n\nTanggal: ${res.data.tanggal}`, 'Checkout Berhasil');
        getAbsensi();
      } else {
        // Regular QR code scan (old flow)
        const res = await axios.post(
          'http://localhost:5000/qr-code/scan',
          { qr_code: text },
          { headers: { Authorization: `Bearer ${token}` } }
        );

        showToast(res.data.message, 'success');
        getAbsensi();
        getQrCodeList();
        setQrScannerResult('');
      }
    } catch (err) {
      console.error(err);
      const errorMsg = err.response?.data?.message || 'QR Code tidak valid atau gagal diproses';
      
      // Check if error adalah time limit
      const isTimeError = err.response?.data?.dailyLimitExceeded;
      if (isTimeError && errorMsg.includes('belum dimulai')) {
        showToast('⏰ ' + errorMsg, 'warning');
        showCustomAlert(`⚠️ ABSEN PULANG BELUM DIBUKA\n\n${errorMsg}\n\nHarap tunggu hingga jam yang ditentukan telah tiba untuk melakukan absen pulang.`, 'Waktu Belum Tiba');
      } else if (isTimeError && errorMsg.includes('berakhir')) {
        showToast('⏰ ' + errorMsg, 'warning');
        showCustomAlert(`⚠️ ABSEN PULANG SUDAH BERAKHIR\n\n${errorMsg}\n\nWaktu absen pulang telah melewati batas yang ditentukan.`, 'Waktu Sudah Berakhir');
      } else {
        showToast(errorMsg, 'error');
      }
    } finally {
      // Always close scanner immediately
      setIsQrScannerOpen(false);
    }
  }

  // ==========================================
  // DIRECT USER CREATION (ADMIN ONLY)
  // ==========================================
  async function createNewUser() {
    if (!newUserUsername || !newUserPassword || !newUserConfirmPassword || !newUserNama) {
      showToast('Username, Password, dan Nama wajib diisi!', 'error');
      return;
    }

    if (newUserPassword !== newUserConfirmPassword) {
      showToast('Password konfirmasi tidak cocok!', 'error');
      return;
    }

    if (newUserPassword.length < 6) {
      showToast('Password minimal 6 karakter!', 'error');
      return;
    }

    setIsCreatingUser(true);

    try {
      console.log(' Creating new user:', newUserUsername);
      const res = await axios.post(
        'http://localhost:5000/user/create',
        {
          username: newUserUsername,
          password: newUserPassword,
          nama: newUserNama,
          divisi_id: newUserDivisiId || null,
          jabatan: newUserJabatan || 'Karyawan'
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      console.log(' User created successfully:', res.data);
      showToast(res.data.message, 'success');
      getPegawai();
      
      // Reset form
      setNewUserUsername('');
      setNewUserPassword('');
      setNewUserConfirmPassword('');
      setNewUserNama('');
      setNewUserDivisiId('');
      setNewUserJabatan('');
    } catch (err) {
      console.error(' Error creating user:', err.response?.data || err.message);
      const errorMsg = err.response?.data?.message || err.message || 'Gagal membuat user';
      showToast(errorMsg, 'error');
    } finally {
      setIsCreatingUser(false);
    }
  }

  // ==========================================
  // RENDER 1: LOGIN PAGE
  // ==========================================
  if (!token) {
    return (
      <div className="login-container">
        <div className="login-card">
          <div className="login-header">
            <span className="login-logo">📋</span>
            <h1>PresensiHub</h1>
            <p>Sistem Absensi Pegawai & Admin Terpadu</p>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="user-field">Username</label>
            <input
              id="user-field"
              type="text"
              className="form-input"
              placeholder="Masukkan Username Anda"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && login()}
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="pass-field">Password</label>
            <div className="input-container">
              <input
                id="pass-field"
                type={showPassword ? 'text' : 'password'}
                className="form-input"
                placeholder="Masukkan Password Anda"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && login()}
              />
              <button
                type="button"
                className="password-toggle-btn"
                onClick={() => setShowPassword(!showPassword)}
                title={showPassword ? 'Sembunyikan password' : 'Tampilkan password'}
              >
                {showPassword ? (
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                ) : (
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                )}
              </button>
            </div>
          </div>

          <button className="btn-primary" onClick={login}>
            Masuk ke Aplikasi 
          </button>
        </div>

        {toast.show && (
          <div className={`custom-toast ${toast.type === 'error' ? 'toast-error' : 'toast-success'}`}>
            <span>{toast.type === 'error' ? '' : ''}</span>
            <span>{toast.message}</span>
          </div>
        )}
      </div>
    );
  }

  // ==========================================
  // RENDER 2: USER / PEGAWAI PORTAL
  // ==========================================
  if (role === 'user') {
    const loggedInName = localStorage.getItem('username') || username;
    const myName = currentEmployee ? currentEmployee.nama : loggedInName;
    
    // Calculate Personal Logs and Quota Limits
    const allMyLogs = absensi.filter((a) => a.nama.toLowerCase() === myName.toLowerCase());
    const myLogs = allMyLogs.filter((a) => a.tanggal.startsWith(selectedMonth));
    const countHadir = myLogs.filter((l) => l.status === 'Hadir').length;
    // Combine Sakit and Izin into single Izin count
    const countIzinAbsensi = myLogs.filter((l) => l.status === 'Izin' || l.status === 'Sakit').length;
    const countAlpa = myLogs.filter((l) => l.status === 'Alpa').length;
    // Count late arrivals (Terlambat) and overtime (Lembur)
    const countTerlambat = myLogs.filter((l) => l.keterangan_jam === 'Terlambat').length;
    const countLembur = myLogs.filter((l) => l.is_lembur == 1).length;

    //  Tambahkan Disetujui Cuti Tambahan yang kategori Izin/Sakit Lanjutan ke grafik
    // Karena absensi record-nya tidak otomatis berubah saat ACC.
    const cutiTambahanInMonth = cuti
      .filter((c) => c.nama && c.nama.toLowerCase() === myName.toLowerCase())
      .filter((c) => c.status === 'Disetujui');

    const countIzinCutiTambahan = cutiTambahanInMonth.reduce((sum, c) => {
      if (c.keperluan !== 'Izin/Sakit Lanjutan') return sum;
      const start = new Date(c.tanggal_mulai);
      const end = new Date(c.tanggal_selesai);

      let cur = new Date(start);
      let localCount = 0;
      // iterasi per hari agar sesuai "jumlah hari" di grafik
      while (cur <= end) {
        const y = cur.getFullYear();
        const m = String(cur.getMonth() + 1).padStart(2, '0');
        const ym = `${y}-${m}`;
        if (ym === selectedMonth) localCount += 1;
        cur.setDate(cur.getDate() + 1);
      }
      return sum + localCount;
    }, 0);

    const countIzin = countIzinAbsensi + countIzinCutiTambahan;




    // Additional Approved leaves
    const myCuti = cuti.filter((c) => c.nama.toLowerCase() === myName.toLowerCase());
    const approvedCutiDays = myCuti
      .filter((c) => c.status === 'Disetujui')
      .reduce((sum, current) => sum + parseInt(current.durasi_hari), 0);

    const totalLeaveCount = allMyLogs.filter((l) => l.status === 'Sakit' || l.status === 'Izin').length;
    const quotaLimit = 7 + approvedCutiDays;
    const isLimitExceeded = totalLeaveCount >= quotaLimit;

    return (
      <div className="app-layout">
        {/* User Header */}
        <header className="app-header">
          <div className="brand">
            <div className="brand-icon">HR</div>
            <span className="brand-name">PresensiHub Pegawai</span>
          </div>
          <div className="header-actions">
            <div className="user-info">
              <div className="avatar" style={{
                width: '40px',
                height: '40px',
                borderRadius: '50%',
                background: currentEmployee?.foto ? 'transparent' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '16px',
                color: '#fff',
                fontWeight: 700,
                overflow: 'hidden',
                flexShrink: 0
              }}>
                {currentEmployee?.foto ? (
                  <img src={currentEmployee.foto} alt={currentEmployee?.nama} style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                    borderRadius: '50%'
                  }} />
                ) : (
                  (currentEmployee?.nama || loggedInName).charAt(0).toUpperCase()
                )}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '14px', color: 'var(--text-heading)' }}>
                  {currentEmployee ? currentEmployee.nama : loggedInName}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Pegawai Aktif</div>
              </div>
            </div>
            <button className="btn-outline" onClick={logout}>
              Keluar 
            </button>
          </div>
        </header>

        {/* User Sub Navigation Tabs */}
        <nav className="dashboard-nav">
          <div
            className={`nav-tab ${userTab === 'presensi' ? 'active' : ''}`}
            onClick={() => setUserTab('presensi')}
          >
             Catat Presensi & QR
          </div>
          <div
            className={`nav-tab ${userTab === 'qr-scan' ? 'active' : ''}`}
            onClick={() => setUserTab('qr-scan')}
          >
             Absen Pulang
          </div>
          <div
            className={`nav-tab ${userTab === 'cuti' ? 'active' : ''}`}
            onClick={() => setUserTab('cuti')}
          >
             Pengajuan Cuti Tambahan
          </div>
          <div
            className={`nav-tab ${userTab === 'pengaturan' ? 'active' : ''}`}
            onClick={() => setUserTab('pengaturan')}
          >
             Pengaturan
          </div>
        </nav>

        <main className="app-content">
          {/* LIMIT EXCEEDED WARNING ALERT */}
          {isLimitExceeded && (
            <div style={{
              background: 'rgba(239, 68, 68, 0.08)',
              borderLeft: '4px solid var(--danger)',
              padding: '16px 24px',
              borderRadius: '8px',
              color: '#991b1b',
              marginBottom: '28px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              fontSize: '14px',
              fontWeight: 600,
              boxShadow: 'var(--shadow-sm)',
              animation: 'float 3s ease-in-out infinite'
            }}>
              <span></span>
              <span>
                Peringatan: Jatah Izin & Sakit (Batas: {quotaLimit} Hari) Anda telah habis! Presensi berikutnya otomatis dicatat sebagai <strong>ALPA</strong>. Silakan ajukan <strong>Cuti Tambahan</strong> agar disetujui Admin.
              </span>
            </div>
          )}

          {/* Stats Bar */}
          <section className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))' }}>
            <div className="stat-card" style={{ gridColumn: 'span 2' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                <div className="avatar" style={{
                  width: '60px',
                  height: '60px',
                  fontSize: '24px',
                  background: currentEmployee?.foto ? 'transparent' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#fff',
                  fontWeight: 700,
                  borderRadius: '50%',
                  border: '2px solid #e2e8f0',
                  overflow: 'hidden',
                  flexShrink: 0
                }}>
                  {currentEmployee?.foto ? (
                    <img src={currentEmployee.foto} alt={currentEmployee?.nama} style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      borderRadius: '50%'
                    }} />
                  ) : (
                    (currentEmployee?.nama || loggedInName).substring(0, 1).toUpperCase()
                  )}
                </div>
                <div>
                  <h2 style={{ fontSize: '22px', marginBottom: '4px' }}>
                    {currentEmployee ? currentEmployee.nama : loggedInName}
                  </h2>
                  <p style={{ color: 'var(--text-muted)', fontSize: '14px', fontWeight: 500 }}>
                    Divisi: <span className="badge badge-primary">{currentEmployee?.nama_divisi || 'Tanpa Divisi'}</span> | Jabatan: <strong style={{ color: 'var(--text-main)' }}>{currentEmployee?.jabatan || '-'}</strong>
                  </p>
                </div>
              </div>
              <div className="stat-icon icon-blue" style={{ width: '60px', height: '60px', fontSize: '26px' }}>👤</div>
            </div>

            <div className="stat-card">
              <div>
                <div className="stat-label">Hadir</div>
                <div className="stat-value" style={{ color: 'var(--success)' }}>{countHadir} Hari</div>
              </div>
              <div className="stat-icon icon-green" style={{ fontSize: '22px' }}>✅</div>
            </div>

            <div className="stat-card">
              <div>
                <div className="stat-label">Izin/Sakit (Limit: {quotaLimit})</div>
                <div className="stat-value" style={{ color: isLimitExceeded ? 'var(--danger)' : 'var(--warning)' }}>
                  {totalLeaveCount} / {quotaLimit} Hari
                </div>
              </div>
              <div className="stat-icon" style={{ background: isLimitExceeded ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)', color: isLimitExceeded ? 'var(--danger)' : 'var(--warning)', fontSize: '22px' }}>
                {isLimitExceeded ? '🚫' : '🏥'}
              </div>
            </div>

            <div className="stat-card">
              <div>
                <div className="stat-label">Alpa</div>
                <div className="stat-value" style={{ color: 'var(--danger)' }}>{countAlpa} Hari</div>
              </div>
              <div className="stat-icon" style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', fontSize: '22px' }}>❌</div>
            </div>


          </section>

          {/* User Tab 1: Attendance Panel */}
          {userTab === 'presensi' && (
            <>
              {/* Attendance Chart */}
              <div className="panel-card" style={{ marginBottom: '28px' }}>
                <div className="panel-header">
                  <span className="panel-title"> Grafik Kehadiran Anda</span>
                  <button className="btn-action btn-action-secondary" onClick={getAbsensi}>Refresh</button>
                </div>
                <div className="panel-body">
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(100px, 1fr))', gap: '16px', marginBottom: '24px' }}>
                    {/* Hadir Chart */}
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{
                          width: '80px',
                          height: '80px',
                          margin: '0 auto',
                          borderRadius: '50%',
                          background: 'conic-gradient(#10b981 ' + ((countHadir / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 360) + 'deg, #e5e7eb 0deg)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: 'var(--text-heading)',
                          fontSize: '20px'
                        }}>
                          {countHadir}
                        </div>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: 0, textTransform: 'uppercase' }}>Hadir</p>
                      <p style={{ fontSize: '16px', fontWeight: 700, color: 'var(--success)', margin: '4px 0 0 0' }}>{countHadir} Hari</p>
                    </div>

                    {/* Izin Chart */}
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{
                          width: '80px',
                          height: '80px',
                          margin: '0 auto',
                          borderRadius: '50%',
                          background: `linear-gradient(135deg, #f59e0b 0%, #f59e0b ${(countIzin / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb ${(countIzin / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb 100%)`,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: 'var(--text-heading)',
                          fontSize: '20px'
                        }}>
                          {countIzin}
                        </div>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: 0, textTransform: 'uppercase' }}>Izin/Sakit</p>
                      <p style={{ fontSize: '16px', fontWeight: 700, color: 'var(--warning)', margin: '4px 0 0 0' }}>{countIzin} Hari</p>
                    </div>

                    {/* Alpa Chart */}
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{
                          width: '80px',
                          height: '80px',
                          margin: '0 auto',
                          borderRadius: '50%',
                          background: `linear-gradient(135deg, #ef4444 0%, #ef4444 ${(countAlpa / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb ${(countAlpa / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb 100%)`,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: 'var(--text-heading)',
                          fontSize: '20px'
                        }}>
                          {countAlpa}
                        </div>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: 0, textTransform: 'uppercase' }}>Alpa</p>
                      <p style={{ fontSize: '16px', fontWeight: 700, color: 'var(--danger)', margin: '4px 0 0 0' }}>{countAlpa} Hari</p>
                    </div>

                    {/* Terlambat Chart */}
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{
                          width: '80px',
                          height: '80px',
                          margin: '0 auto',
                          borderRadius: '50%',
                          background: `linear-gradient(135deg, #dc2626 0%, #dc2626 ${(countTerlambat / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb ${(countTerlambat / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb 100%)`,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: 'var(--text-heading)',
                          fontSize: '20px'
                        }}>
                          {countTerlambat}
                        </div>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: 0, textTransform: 'uppercase' }}>Terlambat</p>
                      <p style={{ fontSize: '16px', fontWeight: 700, color: '#dc2626', margin: '4px 0 0 0' }}>{countTerlambat} Hari</p>
                    </div>

                    {/* Lembur Chart */}
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{
                          width: '80px',
                          height: '80px',
                          margin: '0 auto',
                          borderRadius: '50%',
                          background: `linear-gradient(135deg, #7c3aed 0%, #7c3aed ${(countLembur / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb ${(countLembur / (countHadir + countIzin + countAlpa + countTerlambat + countLembur || 1)) * 100}%, #e5e7eb 100%)`,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: 'var(--text-heading)',
                          fontSize: '20px'
                        }}>
                          {countLembur}
                        </div>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: 0, textTransform: 'uppercase' }}>Lembur</p>
                      <p style={{ fontSize: '16px', fontWeight: 700, color: '#7c3aed', margin: '4px 0 0 0' }}>{countLembur} Hari</p>
                    </div>
                  </div>

                  {/* Bar Chart */}
                  <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '8px', border: '1px solid var(--border)' }}>
                    <p style={{ fontSize: '13px', fontWeight: 700, color: 'var(--text-main)', margin: '0 0 16px 0' }}> Perbandingan Kehadiran</p>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                          <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Hadir</span>
                          <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--success)' }}>{countHadir}</span>
                        </div>
                        <div style={{ width: '100%', height: '8px', background: '#e5e7eb', borderRadius: '4px', overflow: 'hidden' }}>
                          <div style={{ width: (countHadir > 0 ? (countHadir / Math.max(countHadir, countIzin, countAlpa, 1)) * 100 : 0) + '%', height: '100%', background: 'var(--success)', transition: 'width 0.3s ease' }} />
                        </div>
                      </div>
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                          <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Izin/Sakit</span>
                          <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--warning)' }}>{countIzin}</span>
                        </div>
                        <div style={{ width: '100%', height: '8px', background: '#e5e7eb', borderRadius: '4px', overflow: 'hidden' }}>
                          <div style={{ width: (countIzin > 0 ? (countIzin / Math.max(countHadir, countIzin, countAlpa, 1)) * 100 : 0) + '%', height: '100%', background: '#f59e0b', transition: 'width 0.3s ease' }} />
                        </div>
                      </div>
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                          <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Alpa</span>
                          <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--danger)' }}>{countAlpa}</span>
                        </div>
                        <div style={{ width: '100%', height: '8px', background: '#e5e7eb', borderRadius: '4px', overflow: 'hidden' }}>
                          <div style={{ width: (countAlpa > 0 ? (countAlpa / Math.max(countHadir, countIzin, countAlpa, countTerlambat, 1)) * 100 : 0) + '%', height: '100%', background: 'var(--danger)', transition: 'width 0.3s ease' }} />
                        </div>
                      </div>
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                          <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Terlambat</span>
                          <span style={{ fontSize: '12px', fontWeight: 700, color: '#dc2626' }}>{countTerlambat}</span>
                        </div>
                        <div style={{ width: '100%', height: '8px', background: '#e5e7eb', borderRadius: '4px', overflow: 'hidden' }}>
                          <div style={{ width: (countTerlambat > 0 ? (countTerlambat / Math.max(countHadir, countIzin, countAlpa, countTerlambat, countLembur, 1)) * 100 : 0) + '%', height: '100%', background: '#dc2626', transition: 'width 0.3s ease' }} />
                        </div>
                      </div>
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                          <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Lembur</span>
                          <span style={{ fontSize: '12px', fontWeight: 700, color: '#7c3aed' }}>{countLembur}</span>
                        </div>
                        <div style={{ width: '100%', height: '8px', background: '#e5e7eb', borderRadius: '4px', overflow: 'hidden' }}>
                          <div style={{ width: (countLembur > 0 ? (countLembur / Math.max(countHadir, countIzin, countAlpa, countTerlambat, countLembur, 1)) * 100 : 0) + '%', height: '100%', background: '#7c3aed', transition: 'width 0.3s ease' }} />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

            <div className="dashboard-grid two-cols">
              {/* Left Panel: QR actions */}
              <div className="panel-card">
                <div className="panel-header">
                  <span className="panel-title"> Pencatatan Kehadiran Pegawai</span>
                </div>
                <div className="panel-body" style={{ textAlign: 'center' }}>
                  {/* Method 1: Scan camera */}
                  <div style={{ marginBottom: '24px' }}>
                    <h3 style={{ fontSize: '14px', color: 'var(--text-heading)', marginBottom: '12px', fontWeight: 700 }}>
                      1. Scan QR Code Kantor
                    </h3>
                    {isScannerOpen ? (
                      <div style={{ width: '100%', maxWidth: '340px', margin: '0 auto' }}>
                        <div style={{ marginBottom: '8px' }}>
                          <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '8px', fontStyle: 'italic' }}>
                             Arahkan kamera ke QR Code Kantor untuk scan
                          </p>
                        </div>
                        <div id="user-scanner" style={{ 
                          width: '100%', 
                          height: '320px',
                          borderRadius: '12px', 
                          overflow: 'hidden', 
                          background: '#1a1a1a',
                          border: '1px solid #333',
                          display: 'block'
                        }} />
                        <button
                          className="btn-action btn-action-secondary"
                          style={{ 
                            width: '100%', 
                            marginTop: '12px',
                            padding: '12px 16px',
                            fontSize: '14px',
                            fontWeight: '600',
                            borderRadius: '8px',
                            background: 'var(--danger)',
                            color: 'white',
                            border: 'none',
                            cursor: 'pointer',
                            transition: 'all 0.2s ease',
                            boxShadow: '0 2px 8px rgba(239, 68, 68, 0.3)'
                          }}
                          onMouseOver={(e) => e.target.style.background = '#dc2626'}
                          onMouseOut={(e) => e.target.style.background = '#ef4444'}
                          onClick={async () => { 
                            try {
                              if (window.userScanner) {
                                try {
                                  await window.userScanner.clear();
                                } catch (err) {
                                  console.error('Error stopping scanner:', err);
                                }
                                window.userScanner = null;
                              }
                              // Also stop all camera streams
                              document.querySelectorAll('video').forEach((video) => {
                                if (video.srcObject) {
                                  const tracks = video.srcObject.getTracks();
                                  tracks.forEach((track) => track.stop());
                                  video.srcObject = null;
                                }
                              });
                            } catch (err) {
                              console.error('Error in close handler:', err);
                            }
                            setIsScannerOpen(false);
                          }}
                        >
                           Matikan Kamera
                        </button>
                      </div>
                    ) : (
                      <button 
                        className="btn-primary" 
                        style={{ 
                          margin: '0 auto', 
                          maxWidth: '240px', 
                          display: 'block',
                          padding: '12px 24px',
                          fontSize: '14px',
                          fontWeight: '600',
                          borderRadius: '8px',
                          background: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
                          color: 'white',
                          border: 'none',
                          cursor: 'pointer',
                          transition: 'all 0.2s ease',
                          boxShadow: '0 4px 12px rgba(59, 130, 246, 0.3)'
                        }}
                        onMouseOver={(e) => e.target.style.boxShadow = '0 6px 16px rgba(59, 130, 246, 0.4)'}
                        onMouseOut={(e) => e.target.style.boxShadow = '0 4px 12px rgba(59, 130, 246, 0.3)'}
                        onClick={() => { 
                          stopAllCameraStreams(); 
                          setTimeout(() => setIsScannerOpen(true), 100); 
                        }}
                      >
                         Buka Kamera Scanner
                      </button>
                    )}
                  </div>


                  {/* Method 3: Show Personal QR */}
                  <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '20px' }}>
                    <h3 style={{ fontSize: '14px', color: 'var(--text-heading)', marginBottom: '6px', fontWeight: 700 }}>
                      2. QR Code ID Card Pegawai Anda
                    </h3>
                    <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '16px' }}>
                      Perlihatkan QR code ini ke alat pemindai absensi kantor.
                    </p>
                    {employeeQrCode ? (
                      <div style={{ background: 'white', display: 'inline-block', padding: '16px', borderRadius: '16px', boxShadow: 'var(--shadow-md)' }}>
                        <img src={employeeQrCode} alt="Personal QR" style={{ display: 'block', margin: '0 auto' }} />
                        <div style={{ fontSize: '12px', fontWeight: 700, color: 'var(--primary)', marginTop: '8px' }}>
                          ID: PG-{currentEmployee?.id || '?' }
                        </div>
                      </div>
                    ) : (
                      <p style={{ color: 'var(--text-faint)', fontSize: '13px' }}>Membuat QR Code...</p>
                    )}
                  </div>
                </div>
              </div>

              {/* Right Panel: Attendance list - Weekly View */}
              <div className="panel-card" style={{ minWidth: 0 }}>
                {/* Header dengan Kalender Pencarian */}
                <div className="panel-header" style={{ flexWrap: 'wrap', gap: '12px' }}>
                  <span className="panel-title">📅 Riwayat Absensi Anda</span>
                  <div style={{ display: 'inline-flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: 'var(--bg-card,#f8fafc)', border: '1.5px solid var(--border,#e2e8f0)', borderRadius: '10px', padding: '4px 10px' }}>
                      <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: 600, whiteSpace: 'nowrap' }}>🔍 Cari tanggal:</span>
                      <input
                        type="date"
                        value={riwayatSearchDate}
                        max={getLocalDateStr()}
                        onChange={(e) => { setRiwayatSearchDate(e.target.value); setRiwayatWeekIndex(0); }}
                        style={{ border: 'none', background: 'transparent', fontSize: '13px', fontWeight: 600, color: 'var(--primary)', outline: 'none', cursor: 'pointer', padding: '2px 0' }}
                      />
                    </div>
                    <button
                      className="btn-action btn-action-secondary"
                      style={{ padding: '6px 12px', fontSize: '13px' }}
                      onClick={() => { setRiwayatSearchDate(getLocalDateStr()); setRiwayatWeekIndex(0); getAbsensi(); }}
                    >
                      🔄 Hari Ini
                    </button>
                  </div>
                </div>

                {/* Weekly grouped view */}
                {(() => {
                  // Hitung minggu yang mengandung riwayatSearchDate
                  const searchD = new Date(riwayatSearchDate + 'T00:00:00');
                  // Senin = 1, Minggu = 0 → offset ke Senin
                  const dayOfWeek = searchD.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat
                  const offsetToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
                  const anchorMonday = new Date(searchD);
                  anchorMonday.setDate(searchD.getDate() + offsetToMonday);

                  // Hitung senin dari minggu yang aktif berdasarkan offset riwayatWeekIndex
                  // riwayatWeekIndex < 0 artinya minggu sebelumnya (lebih tua)
                  // riwayatWeekIndex > 0 artinya minggu berikutnya (lebih baru)
                  const activeMonday = new Date(anchorMonday);
                  activeMonday.setDate(anchorMonday.getDate() + (riwayatWeekIndex * 7));

                  const weekStart = activeMonday;
                  const weekEnd = new Date(weekStart);
                  weekEnd.setDate(weekStart.getDate() + 6);
                  const weekLabel = `${weekStart.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })} – ${weekEnd.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}`;

                  // Cari logs yang jatuh pada minggu aktif ini
                  const startStr = weekStart.toISOString().slice(0, 10);
                  const endStr = weekEnd.toISOString().slice(0, 10);
                  const activeWeekLogs = allMyLogs.filter(l => l.tanggal >= startStr && l.tanggal <= endStr);

                  // Hitung sublabel (misal: "Minggu Ini", "1 minggu yang lalu", dsb.)
                  const today = new Date();
                  const todayOfWeek = today.getDay();
                  const todayOffsetToMonday = todayOfWeek === 0 ? -6 : 1 - todayOfWeek;
                  const todayMonday = new Date(today);
                  todayMonday.setDate(today.getDate() + todayOffsetToMonday);
                  
                  const todayMondayStr = todayMonday.toISOString().slice(0, 10);
                  const activeMondayStr = activeMonday.toISOString().slice(0, 10);

                  let subtext = "";
                  if (activeMondayStr === todayMondayStr) {
                    subtext = "Minggu Ini";
                  } else {
                    const diffTime = todayMonday - activeMonday;
                    const diffWeeks = Math.round(diffTime / (1000 * 60 * 60 * 24 * 7));
                    if (diffWeeks > 0) {
                      subtext = `${diffWeeks} minggu yang lalu`;
                    } else {
                      subtext = `${Math.abs(diffWeeks)} minggu ke depan`;
                    }
                  }

                  // Statistik minggu ini
                  const wHadir = activeWeekLogs.filter(l => l.status === 'Hadir').length;
                  const wIzin = activeWeekLogs.filter(l => l.status === 'Izin' || l.status === 'Sakit').length;
                  const wAlpa = activeWeekLogs.filter(l => l.status === 'Alpa').length;

                  // Batasi navigasi agar tidak bisa maju melampaui minggu ini
                  const isLatestWeek = activeMondayStr >= todayMondayStr;

                  // Hitung weekKeys: daftar Senin dari setiap minggu yang ada di allMyLogs
                  // Diurutkan dari terbaru ke terlama
                  const weekKeySet = new Set();
                  allMyLogs.forEach(l => {
                    if (!l.tanggal) return;
                    const d = new Date(l.tanggal + 'T00:00:00');
                    const dow = d.getDay();
                    const off = dow === 0 ? -6 : 1 - dow;
                    const mon = new Date(d);
                    mon.setDate(d.getDate() + off);
                    weekKeySet.add(mon.toISOString().slice(0, 10));
                  });
                  // Tambahkan minggu ini jika belum ada
                  weekKeySet.add(todayMondayStr);
                  // Urutkan dari terbaru ke terlama
                  const weekKeys = Array.from(weekKeySet).sort((a, b) => b.localeCompare(a));
                  // targetIdx = indeks dari anchorMonday di weekKeys
                  const anchorMondayStr = anchorMonday.toISOString().slice(0, 10);
                  const targetIdx = weekKeys.indexOf(anchorMondayStr) === -1 ? 0 : weekKeys.indexOf(anchorMondayStr);
                  // activeIdx = indeks dari activeMonday di weekKeys
                  const activeIdx = weekKeys.indexOf(activeMondayStr);

                  return (
                    <div>
                      {/* Navigasi Minggu */}
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px', background: 'linear-gradient(135deg,var(--primary,#4f46e5) 0%,#7c3aed 100%)', color: '#fff', gap: '12px' }}>
                        <button
                          onClick={() => setRiwayatWeekIndex(riwayatWeekIndex - 1)}
                          style={{ background: 'rgba(255,255,255,0.18)', border: 'none', color: '#fff', borderRadius: '8px', padding: '6px 14px', fontSize: '16px', cursor: 'pointer', transition: 'background 0.2s' }}
                          title="Minggu sebelumnya"
                        >‹ Sebelumnya</button>

                        <div style={{ textAlign: 'center', flex: 1 }}>
                          <div style={{ fontWeight: 800, fontSize: '15px', letterSpacing: '0.3px' }}>📆 {weekLabel}</div>
                          <div style={{ fontSize: '11px', opacity: 0.85, marginTop: '3px' }}>
                            {subtext}
                          </div>
                          <div style={{ display: 'flex', gap: '10px', justifyContent: 'center', marginTop: '6px' }}>
                            <span style={{ background: 'rgba(255,255,255,0.2)', borderRadius: '20px', padding: '2px 10px', fontSize: '11px', fontWeight: 700 }}>✅ Hadir: {wHadir}</span>
                            <span style={{ background: 'rgba(255,255,255,0.2)', borderRadius: '20px', padding: '2px 10px', fontSize: '11px', fontWeight: 700 }}>🏥 Izin/Sakit: {wIzin}</span>
                            <span style={{ background: 'rgba(255,255,255,0.2)', borderRadius: '20px', padding: '2px 10px', fontSize: '11px', fontWeight: 700 }}>❌ Alpa: {wAlpa}</span>
                          </div>
                        </div>

                        <button
                          onClick={() => setRiwayatWeekIndex(riwayatWeekIndex + 1)}
                          disabled={isLatestWeek}
                          style={{ background: 'rgba(255,255,255,0.18)', border: 'none', color: '#fff', borderRadius: '8px', padding: '6px 14px', fontSize: '16px', cursor: isLatestWeek ? 'not-allowed' : 'pointer', opacity: isLatestWeek ? 0.4 : 1, transition: 'background 0.2s' }}
                          title="Minggu berikutnya"
                        >Berikutnya ›</button>
                      </div>

                      {/* Tabel data minggu ini */}
                      <div className="table-responsive">
                        {activeWeekLogs.length === 0 ? (
                          <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-faint)' }}>Tidak ada data absensi minggu ini.</div>
                        ) : (
                          <table className="custom-table">
                            <thead>
                              <tr>
                                <th>Tanggal</th>
                                <th>Jam Masuk</th>
                                <th>Jam Keluar</th>
                                <th>Status</th>
                              </tr>
                            </thead>
                            <tbody>
                              {activeWeekLogs
                                .slice()
                                .sort((a, b) => a.tanggal.localeCompare(b.tanggal))
                                .map((a) => {
                                  const formattedDate = new Date(a.tanggal + 'T00:00:00').toLocaleDateString('id-ID', {
                                    weekday: 'long',
                                    day: 'numeric',
                                    month: 'short',
                                    year: 'numeric'
                                  });
                                  let badgeClass = 'badge-success';
                                  if (a.status === 'Izin' || a.status === 'Pending Izin') badgeClass = 'badge-warning';
                                  else if (a.status === 'Sakit' || a.status === 'Pending Sakit') badgeClass = 'badge-primary';
                                  else if (a.status === 'Alpa' || a.status === 'Ditolak') badgeClass = 'badge-danger';
                                  else if (a.status === 'Cuti Tambahan') badgeClass = 'badge-primary';

                                  return (
                                    <tr key={a.id}>
                                      <td>
                                        <div style={{ fontWeight: 700, color: 'var(--text-heading)' }}>{formattedDate}</div>
                                        <div style={{ fontSize: '11px', color: 'var(--text-faint)' }}>Log #{a.id}</div>
                                      </td>
                                      <td>
                                        <div style={{ fontWeight: 600, color: a.status === 'Hadir' ? 'var(--success)' : 'var(--text-faint)' }}>
                                          {a.status === 'Hadir' ? (a.jam_masuk ? `${a.jam_masuk.slice(0, 5)} WIB` : '08:00 WIB') : '-'}
                                        </div>
                                        {a.status === 'Hadir' && a.keterangan_jam === 'Terlambat' && (
                                          <div style={{ fontSize: '11px', color: '#dc2626', fontWeight: 700, marginTop: '2px' }}>⚠ Terlambat</div>
                                        )}
                                        {a.alasan && (
                                          <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px', fontStyle: 'italic' }}>{a.alasan}</div>
                                        )}
                                      </td>
                                      <td>
                                        <div style={{ fontWeight: 600, color: 'var(--text-muted)' }}>
                                          {a.status === 'Hadir' ? (a.jam_keluar ? `${a.jam_keluar.slice(0, 5)} WIB` : 'Belum Pulang') : '-'}
                                        </div>
                                        {a.status === 'Hadir' && a.is_lembur == 1 && (
                                          <div style={{ fontSize: '11px', color: 'var(--warning)', fontWeight: 700, marginTop: '2px' }}>⏰ Lembur</div>
                                        )}
                                      </td>
                                      <td>
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', alignItems: 'center' }}>
                                          <span className={`badge ${badgeClass}`}>{a.status}</span>
                                          {(a.alasan || a.foto_bukti) && (
                                            <button
                                              className="btn-sm-action btn-sm-edit"
                                              style={{ fontSize: '10px', padding: '2px 6px' }}
                                              onClick={() => {
                                                setPreviewImage(a.foto_bukti || 'NO_IMAGE');
                                                setPreviewAlasan(a.alasan || 'Tidak ada alasan.');
                                              }}
                                            >
                                              Detail
                                            </button>
                                          )}
                                        </div>
                                      </td>
                                    </tr>
                                  );
                                })}
                            </tbody>
                          </table>
                        )}
                      </div>

                      {/* Footer: quick jump ke minggu lain */}
                      <div style={{ padding: '10px 20px', borderTop: '1px solid var(--border,#e2e8f0)', display: 'flex', gap: '6px', flexWrap: 'wrap', alignItems: 'center' }}>
                        <span style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>Lompat ke:</span>
                        {weekKeys.slice(0, 8).map((k, i) => {
                          const d = new Date(k + 'T00:00:00');
                          const lbl = d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
                          return (
                            <button
                              key={k}
                              onClick={() => { setRiwayatWeekIndex(i - targetIdx); }}
                              style={{
                                padding: '3px 10px', fontSize: '11px', borderRadius: '20px', border: '1.5px solid var(--primary,#4f46e5)',
                                background: activeIdx === i ? 'var(--primary,#4f46e5)' : 'transparent',
                                color: activeIdx === i ? '#fff' : 'var(--primary,#4f46e5)',
                                cursor: 'pointer', fontWeight: 600, transition: 'all 0.15s'
                              }}
                            >{lbl}</button>
                          );
                        })}
                        {weekKeys.length > 8 && <span style={{ fontSize: '11px', color: 'var(--text-faint)' }}>+{weekKeys.length - 8} minggu lagi (gunakan kalender)</span>}
                      </div>
                    </div>
                  );
                })()}
              </div>
            </div>
            </>
          )}

          {/* User Tab: Scan QR from Admin */}
          {userTab === 'qr-scan' && (
            <div className="panel-card" style={{ maxWidth: '600px', margin: '0 auto' }}>
              <div className="panel-header">
                <span className="panel-title"> Absen Pulang (Checkout)</span>
              </div>
              <div className="panel-body" style={{ textAlign: 'center' }}>
                <p style={{ fontSize: '14px', color: 'var(--text-muted)', marginBottom: '24px' }}>
                  Perlihatkan QR Code ID Card Anda ke Admin untuk mencatat jam pulang Anda.
                </p>

                {/* Display Employee QR Code */}
                <div style={{ 
                  background: '#f8fafc', 
                  padding: '24px', 
                  borderRadius: '16px', 
                  border: '2px dashed var(--primary)',
                  marginBottom: '24px'
                }}>
                  <h4 style={{ fontSize: '13px', color: 'var(--text-heading)', marginBottom: '4px', fontWeight: 700 }}>
                     QR Code ID Card Anda
                  </h4>
                  <p style={{ fontSize: '11px', color: 'var(--text-muted)', marginBottom: '16px' }}>
                    Scan QR code ini untuk mencatat jam pulang
                  </p>
                  
                  {employeeQrCode ? (
                    <div style={{ background: 'white', display: 'inline-block', padding: '20px', borderRadius: '16px', boxShadow: 'var(--shadow-lg)' }}>
                      <img src={employeeQrCode} alt="ID Card QR" style={{ display: 'block', margin: '0 auto', width: '240px', height: '240px' }} />
                      <div style={{ fontSize: '12px', fontWeight: 700, color: 'var(--primary)', marginTop: '12px' }}>
                        ID: PG-{currentEmployee?.id || '?'}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-faint)', marginTop: '4px' }}>
                        {currentEmployee?.nama || 'Pegawai'}
                      </div>
                    </div>
                  ) : (
                    <p style={{ color: 'var(--text-faint)', fontSize: '13px' }}> Membuat QR Code...</p>
                  )}
                </div>

                {/* Time Restriction Info */}
                <div style={{ 
                  background: 'rgba(59, 130, 246, 0.08)',
                  border: '1px solid rgba(59, 130, 246, 0.3)',
                  padding: '14px 16px', 
                  borderRadius: '12px',
                  textAlign: 'center',
                  marginBottom: '16px'
                }}>
                  <div style={{ fontSize: '12px', fontWeight: 700, color: '#1e40af', marginBottom: '4px' }}>
                    ⏰ BATASAN WAKTU CHECKOUT
                  </div>
                  <div style={{ fontSize: '12px', color: '#1e3a8a' }}>
                    Absen pulang dapat dilakukan mulai pukul <strong>{workSettings?.jam_keluar_awal || '16:00'}</strong> hingga <strong>{workSettings?.jam_keluar_akhir || '17:00'}</strong>
                  </div>
                </div>

                {/* Instructions */}
                <div style={{ 
                  background: 'rgba(16, 185, 129, 0.08)',
                  border: '1px solid rgba(16, 185, 129, 0.2)',
                  padding: '16px', 
                  borderRadius: '12px',
                  textAlign: 'left'
                }}>
                  <h4 style={{ fontSize: '13px', fontWeight: 700, color: '#047857', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                     Cara Checkout
                  </h4>
                  <ol style={{ fontSize: '13px', color: 'var(--text-heading)', margin: 0, paddingLeft: '20px', lineHeight: '1.8' }}>
                    <li>Pastikan Anda sudah melakukan absensi masuk di pagi hari</li>
                    <li>Tunggu hingga waktu pulang ({workSettings?.jam_keluar_awal || '16:00'}) telah tiba</li>
                    <li>Ketika ingin pulang, datang ke Admin</li>
                    <li>Perlihatkan QR Code di atas ke Admin</li>
                    <li>Admin akan scan QR Code Anda untuk mencatat jam pulang</li>
                    <li>Selesai! Jam pulang Anda tercatat di sistem</li>
                  </ol>
                </div>
              </div>
            </div>
          )}

          {/* User Tab 2: Leave Request Portal */}
          {userTab === 'cuti' && (() => {
            const sisaBiasa = getSisaKuotaBiasa();
            const isCutiTambahanLocked = sisaBiasa > 0;

            const biasaStart = new Date(biasaTanggalMulai);
            const biasaEnd = new Date(biasaTanggalSelesai);
            const biasaDurasi = Math.max(0, Math.round((biasaEnd - biasaStart) / (1000 * 60 * 60 * 24)) + 1 || 0);
            const isBiasaDisabled = biasaDurasi > sisaBiasa || biasaDurasi <= 0;

            const tambahanStart = new Date(tambahanTanggalMulai);
            const tambahanEnd = new Date(tambahanTanggalSelesai);
            const tambahanDurasi = Math.max(0, Math.round((tambahanEnd - tambahanStart) / (1000 * 60 * 60 * 24)) + 1 || 0);
            const isTambahanDisabled = (tambahanKeperluan === 'Izin/Sakit Lanjutan' && tambahanDurasi > 5) || tambahanDurasi <= 0 || isCutiTambahanLocked;

            return (
              <div className="dashboard-grid two-cols">
                {/* Vertical Forms Container (Left Side) */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
                  
                  {/* FORM 1: CUTI BIASA */}
                  <div className="panel-card">
                    <div className="panel-header">
                      <span className="panel-title"> Formulir Cuti Biasa (Izin / Sakit)</span>
                      <span className="badge badge-primary">Sisa Jatah: {sisaBiasa} Hari</span>
                    </div>
                    <div className="panel-body">
                      <div className="dashboard-form">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                          <div>
                            <label htmlFor="b-tgl-mulai">Tanggal Mulai</label>
                            <input
                              id="b-tgl-mulai"
                              type="date"
                              className="form-input-plain"
                              min={todayStr}
                              value={biasaTanggalMulai}
                              onChange={(e) => { setBiasaTanggalMulai(e.target.value); if (biasaTanggalSelesai < e.target.value) setBiasaTanggalSelesai(e.target.value); }}
                            />
                          </div>
                          <div>
                            <label htmlFor="b-tgl-selesai">Tanggal Selesai</label>
                            <input
                              id="b-tgl-selesai"
                              type="date"
                              className="form-input-plain"
                              min={biasaTanggalMulai || todayStr}
                              value={biasaTanggalSelesai}
                              onChange={(e) => setBiasaTanggalSelesai(e.target.value)}
                            />
                          </div>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f8fafc', padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                          <span style={{ fontSize: '13px', fontWeight: 700, color: 'var(--text-main)' }}>Durasi Cuti Diajukan:</span>
                          <strong style={{ color: isBiasaDisabled ? 'var(--danger)' : 'var(--success)', fontSize: '15px' }}>{biasaDurasi} Hari</strong>
                        </div>

                        <div>
                          <label htmlFor="b-status">Kategori Presensi</label>
                          <select
                            id="b-status"
                            className="form-select"
                            value={biasaStatus}
                            onChange={(e) => setBiasaStatus(e.target.value)}
                          >
                            <option value="Izin">Izin </option>
                            <option value="Sakit">Sakit </option>
                          </select>
                        </div>

                        <div>
                          <label htmlFor="b-alasan">Alasan Cuti</label>
                          <textarea
                            id="b-alasan"
                            className="form-input-plain"
                            rows="3"
                            placeholder="Tulis alasan pengajuan cuti Anda..."
                            value={biasaAlasan}
                            onChange={(e) => setBiasaAlasan(e.target.value)}
                            style={{ resize: 'vertical', width: '100%' }}
                          />
                        </div>

                        <div>
                          <label>Foto Bukti Pendukung</label>
                          <div className="file-uploader-container">
                            <label htmlFor="b-foto" className="file-uploader-label">
                              {biasaFotoBukti ? ' Ubah Gambar Bukti' : ' Pilih Gambar Bukti'}
                            </label>
                            <input
                              id="b-foto"
                              type="file"
                              accept="image/*"
                              style={{ display: 'none' }}
                              onChange={(e) => {
                                if (e.target.files && e.target.files[0]) {
                                  handleFileToBase64(e.target.files[0], (base64) => setBiasaFotoBukti(base64));
                                }
                              }}
                            />
                            {biasaFotoBukti && (
                              <div className="thumbnail-preview-container" style={{ marginTop: '10px', display: 'flex', gap: '8px', alignItems: 'center' }}>
                                <img
                                  src={biasaFotoBukti}
                                  alt="Preview"
                                  className="thumbnail-preview"
                                  style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover', cursor: 'pointer', border: '2px solid var(--primary)' }}
                                  onClick={() => setPreviewImage(biasaFotoBukti)}
                                />
                                <button type="button" className="btn-sm-action btn-sm-delete" onClick={() => setBiasaFotoBukti('')}>
                                  Hapus 
                                </button>
                              </div>
                            )}
                          </div>
                        </div>

                        <button
                          className="btn-action btn-action-primary"
                          onClick={submitCutiBiasa}
                          disabled={isBiasaDisabled}
                          style={{ opacity: isBiasaDisabled ? 0.6 : 1, cursor: isBiasaDisabled ? 'not-allowed' : 'pointer' }}
                        >
                          Ajukan Cuti 
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* FORM 2: CUTI TAMBAHAN */}
                  <div className={`panel-card lockable-form ${isCutiTambahanLocked ? 'locked' : ''}`} style={{ position: 'relative' }}>
                    {isCutiTambahanLocked && (
                      <div className="locked-overlay" style={{
                        position: 'absolute',
                        inset: 0,
                        backgroundColor: 'rgba(255, 255, 255, 0.75)',
                        backdropFilter: 'blur(6px)',
                        zIndex: 20,
                        display: 'flex',
                        flexDirection: 'column',
                        justifyContent: 'center',
                        alignItems: 'center',
                        padding: '24px',
                        textAlign: 'center'
                      }}>
                        <div style={{ fontSize: '32px', marginBottom: '12px' }}></div>
                        <h3 style={{ fontSize: '16px', color: 'var(--text-heading)', marginBottom: '8px' }}>Formulir Cuti Tambahan Terkunci</h3>
                        <p style={{ fontSize: '13px', color: 'var(--text-muted)', maxWidth: '280px', lineHeight: '1.5' }}>
                          Hanya terbuka apabila sisa jatah Cuti Biasa Anda sudah habis (<strong>0 Hari</strong> tersisa).
                        </p>
                      </div>
                    )}
                    <div className="panel-header">
                      <span className="panel-title"> Formulir Cuti Tambahan</span>
                      <span className="badge badge-warning">Kuota Ekstra</span>
                    </div>
                    <div className="panel-body">
                      <div className="dashboard-form">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                          <div>
                            <label htmlFor="t-tgl-mulai">Tanggal Mulai</label>
                            <input
                              id="t-tgl-mulai"
                              type="date"
                              className="form-input-plain"
                              min={todayStr}
                              disabled={isCutiTambahanLocked}
                              value={tambahanTanggalMulai}
                              onChange={(e) => { setTambahanTanggalMulai(e.target.value); if (tambahanTanggalSelesai < e.target.value) setTambahanTanggalSelesai(e.target.value); }}
                            />
                          </div>
                          <div>
                            <label htmlFor="t-tgl-selesai">Tanggal Selesai</label>
                            <input
                              id="t-tgl-selesai"
                              type="date"
                              className="form-input-plain"
                              min={tambahanTanggalMulai || todayStr}
                              disabled={isCutiTambahanLocked}
                              value={tambahanTanggalSelesai}
                              onChange={(e) => setTambahanTanggalSelesai(e.target.value)}
                            />
                          </div>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f8fafc', padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                          <span style={{ fontSize: '13px', fontWeight: 700, color: 'var(--text-main)' }}>Durasi Cuti Diajukan:</span>
                          <strong style={{ color: isTambahanDisabled ? 'var(--danger)' : 'var(--success)', fontSize: '15px' }}>{tambahanDurasi} Hari</strong>
                        </div>

                        <div>
                          <label htmlFor="t-keperluan">Keperluan / Kategori Cuti Tambahan</label>
                          <select
                            id="t-keperluan"
                            className="form-select"
                            disabled={isCutiTambahanLocked}
                            value={tambahanKeperluan}
                            onChange={(e) => setTambahanKeperluan(e.target.value)}
                          >
                            <option value="Izin/Sakit Lanjutan">Izin/Sakit Lanjutan (Maksimal 5 Hari) </option>
                            <option value="Melahirkan">Melahirkan </option>
                            <option value="Menikah">Menikah </option>
                          </select>
                        </div>

                        <div>
                          <label htmlFor="t-alasan">Alasan Cuti Tambahan</label>
                          <textarea
                            id="t-alasan"
                            className="form-input-plain"
                            rows="3"
                            disabled={isCutiTambahanLocked}
                            placeholder="Pemulihan pasca operasi / Sakit lanjutan..."
                            value={tambahanAlasan}
                            onChange={(e) => setTambahanAlasan(e.target.value)}
                            style={{ resize: 'vertical', width: '100%' }}
                          />
                        </div>

                        <div>
                          <label>Foto Bukti Pendukung</label>
                          <div className="file-uploader-container">
                            <label htmlFor="t-foto" className="file-uploader-label" style={{ opacity: isCutiTambahanLocked ? 0.6 : 1, cursor: isCutiTambahanLocked ? 'not-allowed' : 'pointer' }}>
                              {tambahanFotoBukti ? ' Ubah Gambar Bukti' : ' Pilih Gambar Bukti'}
                            </label>
                            <input
                              id="t-foto"
                              type="file"
                              accept="image/*"
                              disabled={isCutiTambahanLocked}
                              style={{ display: 'none' }}
                              onChange={(e) => {
                                if (e.target.files && e.target.files[0]) {
                                  handleFileToBase64(e.target.files[0], (base64) => setTambahanFotoBukti(base64));
                                }
                              }}
                            />
                            {tambahanFotoBukti && (
                              <div className="thumbnail-preview-container" style={{ marginTop: '10px', display: 'flex', gap: '8px', alignItems: 'center' }}>
                                <img
                                  src={tambahanFotoBukti}
                                  alt="Preview"
                                  className="thumbnail-preview"
                                  style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover', cursor: 'pointer', border: '2px solid var(--primary)' }}
                                  onClick={() => setPreviewImage(tambahanFotoBukti)}
                                />
                                <button type="button" className="btn-sm-action btn-sm-delete" onClick={() => setTambahanFotoBukti('')}>
                                  Hapus 
                                </button>
                              </div>
                            )}
                          </div>
                        </div>

                        <button
                          className="btn-action btn-action-primary"
                          onClick={submitCutiTambahan}
                          disabled={isTambahanDisabled}
                          style={{ opacity: isTambahanDisabled ? 0.6 : 1, cursor: isTambahanDisabled ? 'not-allowed' : 'pointer' }}
                        >
                          Ajukan Cuti Tambahan 
                        </button>
                      </div>
                    </div>
                  </div>

                </div>

                {/* Status List (Right Side) */}
                <div className="panel-card" style={{ alignSelf: 'start' }}>
                  <div className="panel-header">
                    <span className="panel-title"> Status Pengajuan Cuti Anda</span>
                    <button className="btn-action btn-action-secondary" onClick={getCuti}>Refresh</button>
                  </div>
                  <div className="table-responsive">
                    {myCuti.length === 0 ? (
                      <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-faint)' }}>
                        Belum ada riwayat pengajuan cuti tambahan.
                      </div>
                    ) : (
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Pengajuan</th>
                            <th>Detail Cuti</th>
                            <th>Durasi</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {myCuti.map((c) => {
                            const fDate = new Date(c.tanggal_pengajuan).toLocaleDateString('id-ID', {
                              year: 'numeric',
                              month: 'short',
                              day: 'numeric'
                            });
                            const fMulai = c.tanggal_mulai ? new Date(c.tanggal_mulai).toLocaleDateString('id-ID', { month: 'short', day: 'numeric' }) : '';
                            const fSelesai = c.tanggal_selesai ? new Date(c.tanggal_selesai).toLocaleDateString('id-ID', { month: 'short', day: 'numeric', year: 'numeric' }) : '';
                            let badgeClass = 'badge-warning';
                            if (c.status === 'Disetujui') badgeClass = 'badge-success';
                            else if (c.status === 'Ditolak') badgeClass = 'badge-danger';

                            return (
                              <tr key={c.id}>
                                <td>
                                  <div style={{ fontWeight: 700 }}>{fDate}</div>
                                  <div style={{ fontSize: '11px', color: 'var(--text-faint)' }}>Req #{c.id}</div>
                                </td>
                                <td>
                                  <div style={{ fontSize: '13px', fontWeight: 700, color: 'var(--primary)' }}>{c.keperluan || 'Cuti Tambahan'}</div>
                                  {c.tanggal_mulai && (
                                    <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: 600 }}>{fMulai} - {fSelesai}</div>
                                  )}
                                  <div style={{ maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontStyle: 'italic', fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }} title={c.alasan}>{c.alasan}</div>
                                </td>
                                <td><strong>{c.durasi_hari} Hari</strong></td>
                                <td>
                                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', alignItems: 'center' }}>
                                    <span className={`badge ${badgeClass}`}>{c.status}</span>
                                    {(c.alasan || c.foto_bukti) && (
                                      <button
                                        className="btn-sm-action btn-sm-edit"
                                        style={{ fontSize: '10px', padding: '2px 6px' }}
                                        onClick={() => {
                                          setPreviewImage(c.foto_bukti || 'NO_IMAGE');
                                          setPreviewAlasan(c.alasan || 'Tidak ada alasan.');
                                        }}
                                      >
                                         Detail
                                      </button>
                                    )}
                                  </div>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    )}
                  </div>
                </div>
              </div>
            );
          })()}

          {/* User Tab 4: Settings Panel */}
          {userTab === 'pengaturan' && (
            <div className="dashboard-grid two-cols">
              {/* Left Panel: Profile Photo */}
              <div className="panel-card">
                <div className="panel-header">
                  <span className="panel-title">Ubah Foto Profil</span>
                </div>
                <div className="panel-body" style={{ textAlign: 'center' }}>
                  <div style={{ marginBottom: '24px' }}>
                    <div style={{
                      width: '120px',
                      height: '120px',
                      borderRadius: '50%',
                      margin: '0 auto 20px',
                      objectFit: 'cover',
                      border: '4px solid var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '48px',
                      background: settingsUserFoto ? 'transparent' : '#f0f4f8'
                    }}>
                      {settingsUserFoto ? (
                        <img 
                          src={settingsUserFoto} 
                          alt="Preview Foto"
                          style={{
                            width: '100%',
                            height: '100%',
                            borderRadius: '50%',
                            objectFit: 'cover'
                          }}
                        />
                      ) : (currentEmployee?.foto ? (
                        <img 
                          src={currentEmployee.foto} 
                          alt={currentEmployee.nama}
                          style={{
                            width: '100%',
                            height: '100%',
                            borderRadius: '50%',
                            objectFit: 'cover'
                          }}
                        />
                      ) : (
                        <span style={{ color: '#cbd5e1', fontSize: '14px', fontWeight: 500 }}>Tidak ada foto</span>
                      ))}
                    </div>
                  </div>

                  <div style={{ marginBottom: '20px' }}>
                    <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '12px', fontWeight: 500 }}>
                      Ukuran maksimal: 5MB | Format: JPG, PNG, WebP
                    </p>
                    <label htmlFor="settings-foto" style={{
                      display: 'inline-block',
                      padding: '10px 20px',
                      background: 'var(--primary)',
                      color: 'white',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      fontWeight: 600,
                      fontSize: '14px',
                      transition: 'all 0.2s ease',
                      border: 'none'
                    }}
                    onMouseOver={(e) => {
                      e.currentTarget.style.background = '#2563eb';
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 8px 16px rgba(59, 130, 246, 0.3)';
                    }}
                    onMouseOut={(e) => {
                      e.currentTarget.style.background = 'var(--primary)';
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}>
                      Pilih Foto Baru
                    </label>
                    <input
                      id="settings-foto"
                      type="file"
                      accept="image/*"
                      style={{ display: 'none' }}
                      onChange={handleSettingsFotoChange}
                      disabled={isUploadingUserFoto}
                    />
                  </div>

                  {settingsUserFoto && (
                    <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
                      <button
                        className="btn-action btn-action-primary"
                        onClick={updateUserProfile}
                        disabled={isUploadingUserFoto}
                        style={{ flex: 1 }}
                      >
                        Simpan Foto
                      </button>
                      <button
                        className="btn-action btn-action-secondary"
                        onClick={() => setSettingsUserFoto('')}
                        style={{ flex: 1 }}
                      >
                        Batal
                      </button>
                    </div>
                  )}

                  <p style={{ fontSize: '12px', color: 'var(--text-faint)', fontStyle: 'italic', marginTop: '16px' }}>
                    Foto Anda akan ditampilkan di profil dan dokumen resmi.
                  </p>
                </div>
              </div>

              {/* Right Panel: Password Settings */}
              <div className="panel-card">
                <div className="panel-header">
                  <span className="panel-title">Keamanan Akun</span>
                </div>
                <div className="panel-body">
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {/* Account Info */}
                    <div style={{
                      background: '#f8fafc',
                      padding: '16px',
                      borderRadius: '12px',
                      border: '1px solid var(--border)'
                    }}>
                      <div style={{ marginBottom: '12px' }}>
                        <p style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600, margin: '0 0 4px 0', textTransform: 'uppercase' }}>
                          Username
                        </p>
                        <p style={{ fontSize: '16px', color: 'var(--text-heading)', margin: 0, fontWeight: 700 }}>
                          {currentEmployee?.nama || localStorage.getItem('username')}
                        </p>
                      </div>
                    </div>

                    {/* Change Password Button */}
                    {!showPasswordFields ? (
                      <button
                        className="btn-action btn-action-primary"
                        onClick={() => setShowPasswordFields(true)}
                        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', fontSize: '14px', fontWeight: 600 }}
                      >
                        Ubah Password
                      </button>
                    ) : (
                      <div style={{ animation: 'slideUp 0.3s' }}>
                        <div style={{ marginBottom: '12px' }}>
                          <label style={{ fontSize: '13px', color: 'var(--text-main)', fontWeight: 600, display: 'block', marginBottom: '6px' }}>
                            Password Lama
                          </label>
                          <div className="input-container">
                            <input
                              type={showAdminOldPass ? 'text' : 'password'}
                              className="form-input-plain"
                              placeholder="Masukkan password lama Anda"
                              value={settingsOldPassword}
                              onChange={(e) => setSettingsOldPassword(e.target.value)}
                              style={{ width: '100%', paddingRight: '42px' }}
                            />
                            <button
                              type="button"
                              className="password-toggle-btn"
                              onClick={() => setShowAdminOldPass(!showAdminOldPass)}
                              title={showAdminOldPass ? 'Sembunyikan password' : 'Tampilkan password'}
                            >
                              {showAdminOldPass ? (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                              ) : (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                              )}
                            </button>
                          </div>
                        </div>

                        <div style={{ marginBottom: '12px' }}>
                          <label style={{ fontSize: '13px', color: 'var(--text-main)', fontWeight: 600, display: 'block', marginBottom: '6px' }}>
                            Password Baru
                          </label>
                          <div className="input-container">
                            <input
                              type={showAdminNewPass ? 'text' : 'password'}
                              className="form-input-plain"
                              placeholder="Masukkan password baru (minimal 6 karakter)"
                              value={settingsNewPassword}
                              onChange={(e) => setSettingsNewPassword(e.target.value)}
                              style={{ width: '100%', paddingRight: '42px' }}
                            />
                            <button
                              type="button"
                              className="password-toggle-btn"
                              onClick={() => setShowAdminNewPass(!showAdminNewPass)}
                              title={showAdminNewPass ? 'Sembunyikan password' : 'Tampilkan password'}
                            >
                              {showAdminNewPass ? (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                              ) : (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                              )}
                            </button>
                          </div>
                        </div>

                        <div style={{ marginBottom: '16px' }}>
                          <label style={{ fontSize: '13px', color: 'var(--text-main)', fontWeight: 600, display: 'block', marginBottom: '6px' }}>
                            Konfirmasi Password Baru
                          </label>
                          <div className="input-container">
                            <input
                              type={showAdminConfirmPass ? 'text' : 'password'}
                              className="form-input-plain"
                              placeholder="Konfirmasi password baru"
                              value={settingsConfirmPassword}
                              onChange={(e) => setSettingsConfirmPassword(e.target.value)}
                              style={{ width: '100%', paddingRight: '42px' }}
                            />
                            <button
                              type="button"
                              className="password-toggle-btn"
                              onClick={() => setShowAdminConfirmPass(!showAdminConfirmPass)}
                              title={showAdminConfirmPass ? 'Sembunyikan password' : 'Tampilkan password'}
                            >
                              {showAdminConfirmPass ? (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                              ) : (
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                              )}
                            </button>
                          </div>
                        </div>

                        <div style={{ display: 'flex', gap: '10px' }}>
                          <button
                            className="btn-action btn-action-primary"
                            onClick={updateUserPassword}
                            style={{ flex: 1 }}
                          >
                            Simpan Password
                          </button>
                          <button
                            className="btn-action btn-action-secondary"
                            onClick={() => {
                              setShowPasswordFields(false);
                              setSettingsOldPassword('');
                              setSettingsNewPassword('');
                              setSettingsConfirmPassword('');
                            }}
                            style={{ flex: 1 }}
                          >
                            Batal
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Password Requirements */}
                    <div style={{
                      background: 'rgba(245, 158, 11, 0.08)',
                      border: '1px solid rgba(245, 158, 11, 0.3)',
                      borderRadius: '8px',
                      padding: '12px',
                      marginTop: '8px'
                    }}>
                      <p style={{ fontSize: '12px', fontWeight: 600, color: '#92400e', margin: '0 0 8px 0' }}>
                        Persyaratan Password:
                      </p>
                      <ul style={{ fontSize: '12px', color: '#78350f', margin: '0', paddingLeft: '20px' }}>
                        <li>Minimal 6 karakter</li>
                        <li>Jangan bagikan dengan siapapun</li>
                        <li>Gunakan kombinasi huruf dan angka</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>

              {/* Middle Panel: Account Info */}
              <div className="panel-card">
                <div className="panel-header">
                  <span className="panel-title">Informasi Akun</span>
                </div>
                <div className="panel-body">
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {/* Info Box */}
                    <div style={{
                      background: 'rgba(59, 130, 246, 0.08)',
                      border: '1px solid rgba(59, 130, 246, 0.3)',
                      borderRadius: '8px',
                      padding: '12px'
                    }}>
                      <div style={{ fontSize: '12px', color: '#3730a3', lineHeight: '1.6' }}>
                        <div><strong>Status:</strong> Pegawai Aktif </div>
                        <div><strong>Role:</strong> User</div>
                        <div><strong>Bergabung:</strong> {new Date().getFullYear()}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </main>

        {toast.show && (
          <div className={`custom-toast ${toast.type === 'error' ? 'toast-error' : 'toast-success'}`}>
            <span>{toast.type === 'error' ? '' : ''}</span>
            <span>{toast.message}</span>
          </div>
        )}

        {/* MODAL: PREVIEW DETAIL */}
        {previewImage && (
          <div style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.85)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 2000, padding: '20px'
          }} onClick={() => { setPreviewImage(''); setPreviewAlasan(''); }}>
            <div style={{
              background: 'white', padding: '24px', borderRadius: '16px',
              maxWidth: '500px', width: '100%', textAlign: 'center'
            }} onClick={e => e.stopPropagation()}>
              <h3 style={{ marginBottom: '16px' }}>Detail Pengajuan</h3>
              {previewAlasan && (
                <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '8px', marginBottom: '16px', fontSize: '14px', textAlign: 'left' }}>
                  <strong>Alasan:</strong><br />{previewAlasan}
                </div>
              )}
              {previewImage !== 'NO_IMAGE' && (
                <img src={previewImage} alt="Bukti" style={{ width: '100%', borderRadius: '8px' }} />
              )}
              <button className="btn-action btn-action-primary" style={{ marginTop: '20px', width: '100%' }} onClick={() => { setPreviewImage(''); setPreviewAlasan(''); }}>Tutup</button>
            </div>
          </div>
        )}

        {/* MODAL: CUTI NOTIFICATION (DITOLAK/DITERIMA) */}
        {role === 'user' && cutiNotifModal && (
          <div
            style={{
              position: 'fixed', inset: 0,
              background: 'rgba(15, 23, 42, 0.65)',
              backdropFilter: 'blur(8px)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              zIndex: 1300, padding: '20px'
            }}
            onClick={() => {
              // mark read and close
              const ids = cutiNotifModal && cutiNotifModal.id ? [cutiNotifModal.id] : [];
              markCutiNotifAsRead(ids);
            }}
          >
            <div
              style={{
                background: 'rgba(255,255,255,0.97)',
                borderRadius: '24px', padding: '28px',
                width: '100%', maxWidth: '460px',
                boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
                animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)',
                textAlign: 'left'
              }}
              onClick={(e) => e.stopPropagation()}
            >
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '14px', marginBottom: '16px' }}>
                <div
                  style={{
                    width: '52px', height: '52px', borderRadius: '14px', flexShrink: 0,
                    background: cutiNotifModal.status === 'Ditolak' ? 'rgba(239,68,68,0.12)' : 'rgba(16,185,129,0.12)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '24px'
                  }}
                >
                  {cutiNotifModal.status === 'Ditolak' ? '' : ''}
                </div>
                <div style={{ flex: 1 }}>
                  <h2 style={{ fontSize: '18px', fontWeight: 900, color: 'var(--text-heading)', marginBottom: '4px' }}>
                    {cutiNotifModal.status === 'Ditolak' ? 'Cuti Tidak Diterima' : 'Cuti Disetujui'}
                  </h2>
                  <div style={{ fontSize: '12px', color: 'var(--text-faint)' }}>
                    {cutiNotifModal.tanggal_mulai && cutiNotifModal.tanggal_selesai
                      ? `${new Date(cutiNotifModal.tanggal_mulai).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })} - ${new Date(cutiNotifModal.tanggal_selesai).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}`
                      : 'Pengajuan cuti'}
                  </div>
                </div>
              </div>

              <div style={{ background: '#f8fafc', border: '1px solid var(--border)', borderRadius: '12px', padding: '12px', marginBottom: '16px' }}>
                <div style={{ fontSize: '13px', color: 'var(--text-main)', fontWeight: 700, marginBottom: '6px' }}>
                  Detail
                </div>
                <div style={{ fontSize: '13px', color: 'var(--text-heading)', lineHeight: 1.6 }}>
                  <div><strong>Keperluan:</strong> {cutiNotifModal.keperluan || 'Cuti Tambahan'}</div>
                  <div><strong>Durasi:</strong> {cutiNotifModal.durasi_hari ? `${cutiNotifModal.durasi_hari} hari` : '-'}</div>
                  <div><strong>Alasan:</strong> {cutiNotifModal.alasan || '-'}</div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  className="btn-action btn-action-primary"
                  style={{ flex: 1, padding: '12px' }}
                  onClick={() => {
                    const ids = cutiNotifModal && cutiNotifModal.id ? [cutiNotifModal.id] : [];
                    markCutiNotifAsRead(ids);
                  }}
                  disabled={isCutiNotifMarkingRead}
                >
                  {isCutiNotifMarkingRead ? 'Memproses...' : 'Mengerti'}
                </button>
                <button
                  className="btn-action btn-action-secondary"
                  style={{ flex: 1, padding: '12px' }}
                  onClick={() => {
                    const ids = cutiNotifModal && cutiNotifModal.id ? [cutiNotifModal.id] : [];
                    markCutiNotifAsRead(ids);
                  }}
                  disabled={isCutiNotifMarkingRead}
                >
                  Tutup
                </button>
              </div>
            </div>
          </div>
        )}

        {/* MODAL: GANTI PASSWORD */}
        {isChangePasswordOpen && (
          <div style={{
            position: 'fixed', inset: 0,
            background: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(8px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 1100, padding: '20px'
          }}>

            <div style={{
              background: 'rgba(255,255,255,0.97)',
              borderRadius: '24px', padding: '32px',
              width: '100%', maxWidth: '420px',
              boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
              animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '6px' }}> Ganti Password</h2>
              <p style={{ fontSize: '13px', color: 'var(--text-faint)', marginBottom: '20px' }}>Masukkan password lama dan password baru Anda.</p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
                <div className="input-container">
                  <input
                    type={showUserOldPass ? 'text' : 'password'}
                    className="form-input-plain"
                    placeholder="Password Lama"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    style={{ paddingRight: '42px' }}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowUserOldPass(!showUserOldPass)}
                    title={showUserOldPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showUserOldPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
                <div className="input-container">
                  <input
                    type={showUserNewPass ? 'text' : 'password'}
                    className="form-input-plain"
                    placeholder="Password Baru"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    style={{ paddingRight: '42px' }}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowUserNewPass(!showUserNewPass)}
                    title={showUserNewPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showUserNewPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '10px' }}>
                <button className="btn-action btn-action-primary" style={{ flex: 1, padding: '12px' }} onClick={ubahPassword}>
                  Simpan Password 
                </button>
                <button className="btn-action btn-action-secondary" style={{ flex: 1, padding: '12px' }} onClick={() => { setIsChangePasswordOpen(false); setOldPassword(''); setNewPassword(''); }}>
                  Batal
                </button>
              </div>
            </div>
          </div>
        )}


        {/* MODAL: PENGAJUAN IZIN / SAKIT */}
        {izinSakitModal.show && (
          <div style={{
            position: 'fixed', inset: 0,
            background: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(8px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 1100, padding: '20px'
          }}>
            <div style={{
              background: 'rgba(255,255,255,0.97)',
              borderRadius: '16px', padding: '20px',
              width: '100%', maxWidth: '420px',
              maxHeight: '90vh', overflowY: 'auto',
              boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
              animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              {/* Icon & Judul */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
                <div style={{
                  width: '40px', height: '40px', borderRadius: '10px', flexShrink: 0,
                  background: izinSakitModal.type === 'Izin' ? 'rgba(245,158,11,0.12)' : 'rgba(6,182,212,0.12)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px'
                }}>
                  {izinSakitModal.type === 'Izin' ? '' : ''}
                </div>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '2px' }}>
                    Pengajuan {izinSakitModal.type}
                  </h2>
                  <p style={{ fontSize: '11px', color: 'var(--text-faint)' }}>
                    Pengajuan akan dikirim ke Admin untuk disetujui.
                  </p>
                </div>
              </div>

              {/* Form */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '16px' }}>
                {/* Date Range */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', marginBottom: '4px' }}>
                      Tanggal Mulai *
                    </label>
                    <input
                      type="date"
                      className="form-input-plain"
                      value={izinSakitTanggalMulai || getLocalDateStr()}
                      min={getLocalDateStr()}
                      onChange={(e) => {
                        setIzinSakitTanggalMulai(e.target.value);
                        if (!izinSakitTanggalSelesai || izinSakitTanggalSelesai < e.target.value) {
                          setIzinSakitTanggalSelesai(e.target.value);
                        }
                      }}
                      style={{ width: '100%', padding: '8px 10px', fontSize: '13px' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', marginBottom: '4px' }}>
                      Tanggal Selesai *
                    </label>
                    <input
                      type="date"
                      className="form-input-plain"
                      value={izinSakitTanggalSelesai || getLocalDateStr()}
                      min={izinSakitTanggalMulai || getLocalDateStr()}
                      onChange={(e) => setIzinSakitTanggalSelesai(e.target.value)}
                      style={{ width: '100%', padding: '8px 10px', fontSize: '13px' }}
                    />
                  </div>
                </div>
                {/* Duration info */}
                {izinSakitTanggalMulai && izinSakitTanggalSelesai && (() => {
                  const s = new Date(izinSakitTanggalMulai), e = new Date(izinSakitTanggalSelesai);
                  const d = Math.round((e - s) / (1000 * 60 * 60 * 24)) + 1;
                  return d > 0 ? (
                    <div style={{ background: 'rgba(99,102,241,0.08)', borderRadius: '8px', padding: '6px 10px', fontSize: '12px', color: 'var(--primary)', fontWeight: 600 }}>
                      ⏱️ Durasi pengajuan: <strong>{d} hari</strong>
                    </div>
                  ) : null;
                })()}
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', marginBottom: '4px' }}>
                    Keterangan / Alasan *
                  </label>
                  <textarea
                    className="form-input-plain"
                    rows="3"
                    placeholder={`Tuliskan alasan ${izinSakitModal.type === 'Izin' ? 'izin' : 'sakit'} Anda secara singkat...`}
                    value={izinSakitAlasan}
                    onChange={(e) => setIzinSakitAlasan(e.target.value)}
                    style={{ resize: 'vertical', width: '100%', padding: '8px 10px', fontSize: '13px' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', marginBottom: '4px' }}>
                    Foto Bukti (Opsional)
                  </label>
                  <div className="file-uploader-container">
                    <label htmlFor="izin-sakit-foto" className="file-uploader-label" style={{ padding: '8px 12px', fontSize: '12px' }}>
                      {izinSakitFoto ? ' Ubah Foto Bukti' : ' Pilih Foto Bukti'}
                    </label>
                    <input
                      id="izin-sakit-foto"
                      type="file"
                      accept="image/*"
                      style={{ display: 'none' }}
                      onChange={(e) => {
                        if (e.target.files && e.target.files[0]) {
                          handleFileToBase64(e.target.files[0], (base64) => setIzinSakitFoto(base64));
                        }
                      }}
                    />
                    {izinSakitFoto && (
                      <div style={{ marginTop: '8px', display: 'flex', gap: '8px', alignItems: 'center' }}>
                        <img
                          src={izinSakitFoto}
                          alt="Preview"
                          style={{ width: '48px', height: '48px', borderRadius: '6px', objectFit: 'cover', cursor: 'pointer', border: '1px solid var(--primary)' }}
                          onClick={() => setPreviewImage(izinSakitFoto)}
                        />
                        <button type="button" className="btn-sm-action btn-sm-delete" onClick={() => setIzinSakitFoto('')} style={{ padding: '4px 8px', fontSize: '11px' }}>
                          Hapus 
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Tombol Aksi */}
              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  className="btn-action btn-action-primary"
                  style={{
                    flex: 1, padding: '10px', fontSize: '13px',
                    background: izinSakitModal.type === 'Izin' ? 'linear-gradient(135deg, #f59e0b, #d97706)' : 'linear-gradient(135deg, #06b6d4, #0891b2)'
                  }}
                  onClick={submitIzinSakit}
                >
                  Kirim Pengajuan {izinSakitModal.type === 'Izin' ? '' : ''}
                </button>
                <button
                  className="btn-action btn-action-secondary"
                  style={{ flex: 1, padding: '10px', fontSize: '13px' }}
                  onClick={() => { setIzinSakitModal({ show: false, type: '' }); setIzinSakitAlasan(''); setIzinSakitFoto(''); setIzinSakitTanggalMulai(''); setIzinSakitTanggalSelesai(''); }}
                >
                  Batal
                </button>
              </div>
            </div>
          </div>
        )}

        {/* POPUP MODAL WARNING APABILA KUOTA HABIS */}
        {showQuotaAlert && (
          <div style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(8px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1100,
            padding: '20px'
          }}>
            <div style={{
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(239, 68, 68, 0.2)',
              borderRadius: '24px',
              padding: '32px',
              width: '100%',
              maxWidth: '460px',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              textAlign: 'center',
              animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              <div style={{
                width: '80px',
                height: '80px',
                background: 'rgba(239, 68, 68, 0.1)',
                color: 'var(--danger)',
                fontSize: '36px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: '50%',
                margin: '0 auto 20px auto',
                animation: 'pulse 2s infinite'
              }}>
                
              </div>
              <h2 style={{
                fontSize: '22px',
                fontWeight: 800,
                color: 'var(--text-heading)',
                marginBottom: '12px'
              }}>
                Batas Sakit/Izin Tercapai!
              </h2>
              <p style={{
                fontSize: '15px',
                color: 'var(--text-muted)',
                lineHeight: '1.6',
                marginBottom: '24px'
              }}>
                Jatah izin dan sakit Anda telah mencapai batas maksimal <strong>{quotaLimit} hari</strong>. <br />
                <span style={{ color: 'var(--danger)', fontWeight: 600 }}>Setiap ketidakhadiran berikutnya otomatis akan dicatat sebagai ALPA.</span>
              </p>
              <div style={{
                background: '#f8fafc',
                border: '1px solid var(--border)',
                borderRadius: '16px',
                padding: '16px',
                marginBottom: '24px',
                textAlign: 'left'
              }}>
                <div style={{ fontSize: '13px', color: 'var(--text-main)', marginBottom: '4px' }}>
                   <strong>Solusi:</strong>
                </div>
                <div style={{ fontSize: '13px', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                  Silakan mengajukan <strong>Cuti Tambahan</strong> melalui menu pengajuan agar disetujui (ACC) oleh Admin untuk memulihkan kuota Anda.
                </div>
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                <button 
                  className="btn-action btn-action-primary" 
                  style={{ flex: 1, padding: '12px' }}
                  onClick={() => {
                    setUserTab('cuti');
                    setShowQuotaAlert(false);
                  }}
                >
                  Ajukan Cuti 
                </button>
                <button 
                  className="btn-action btn-action-secondary" 
                  style={{ flex: 1, padding: '12px' }}
                  onClick={() => setShowQuotaAlert(false)}
                >
                  Mengerti
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ===== CUSTOM ALERT MODAL (pengganti alert() bawaan browser) ===== */}
        {customAlert.show && (
          <div style={{
            position: 'fixed', inset: 0,
            background: 'rgba(15,23,42,0.65)', backdropFilter: 'blur(8px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 9999, padding: '20px'
          }}>
            <div style={{
              background: 'var(--bg-card)', borderRadius: '20px',
              padding: '32px', width: '100%', maxWidth: '440px',
              boxShadow: '0 25px 50px -12px rgba(0,0,0,0.35)',
              border: '1px solid var(--border)',
              animation: 'scaleUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              {/* Header Kelompok 2 */}
              <div style={{
                display: 'flex', alignItems: 'center', gap: '10px',
                marginBottom: '18px', paddingBottom: '14px',
                borderBottom: '1px solid var(--border)'
              }}>
                <div style={{
                  width: '36px', height: '36px', borderRadius: '10px',
                  background: 'var(--primary)', display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                  fontSize: '18px', flexShrink: 0
                }}>💡</div>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Kelompok 2</div>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-heading)' }}>{customAlert.title}</div>
                </div>
              </div>
              {/* Pesan */}
              <div style={{
                fontSize: '14px', color: 'var(--text-main)', lineHeight: '1.7',
                whiteSpace: 'pre-line', marginBottom: '24px',
                background: 'var(--bg-subtle)', borderRadius: '12px', padding: '14px 16px'
              }}>
                {customAlert.message}
              </div>
              <button
                onClick={() => setCustomAlert({ show: false, title: '', message: '' })}
                style={{
                  width: '100%', padding: '11px',
                  background: 'var(--primary)', color: '#fff',
                  border: 'none', borderRadius: '10px',
                  fontWeight: 700, fontSize: '14px', cursor: 'pointer',
                  transition: 'opacity 0.2s'
                }}
                onMouseOver={e => e.target.style.opacity = '0.88'}
                onMouseOut={e => e.target.style.opacity = '1'}
              >
                OK
              </button>
            </div>
          </div>
        )}

        {/* ===== CUSTOM CONFIRM MODAL (pengganti window.confirm() bawaan browser) ===== */}
        {customConfirm.show && (
          <div style={{
            position: 'fixed', inset: 0,
            background: 'rgba(15,23,42,0.65)', backdropFilter: 'blur(8px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 9999, padding: '20px'
          }}>
            <div style={{
              background: 'var(--bg-card)', borderRadius: '20px',
              padding: '32px', width: '100%', maxWidth: '440px',
              boxShadow: '0 25px 50px -12px rgba(0,0,0,0.35)',
              border: '1px solid var(--border)',
              animation: 'scaleUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              {/* Header Kelompok 2 */}
              <div style={{
                display: 'flex', alignItems: 'center', gap: '10px',
                marginBottom: '18px', paddingBottom: '14px',
                borderBottom: '1px solid var(--border)'
              }}>
                <div style={{
                  width: '36px', height: '36px', borderRadius: '10px',
                  background: 'rgba(239,68,68,0.12)', display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                  fontSize: '18px', flexShrink: 0
                }}>⚠️</div>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Kelompok 2</div>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-heading)' }}>{customConfirm.title}</div>
                </div>
              </div>
              {/* Pesan */}
              <div style={{
                fontSize: '14px', color: 'var(--text-main)', lineHeight: '1.7',
                whiteSpace: 'pre-line', marginBottom: '24px',
                background: 'var(--bg-subtle)', borderRadius: '12px', padding: '14px 16px'
              }}>
                {customConfirm.message}
              </div>
              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  onClick={() => {
                    setCustomConfirm({ show: false, title: '', message: '', onConfirm: null });
                  }}
                  style={{
                    flex: 1, padding: '11px',
                    background: 'var(--bg-subtle)', color: 'var(--text-main)',
                    border: '1px solid var(--border)', borderRadius: '10px',
                    fontWeight: 600, fontSize: '14px', cursor: 'pointer'
                  }}
                >
                  Batal
                </button>
                <button
                  onClick={() => {
                    const fn = customConfirm.onConfirm;
                    setCustomConfirm({ show: false, title: '', message: '', onConfirm: null });
                    if (fn) fn();
                  }}
                  style={{
                    flex: 1, padding: '11px',
                    background: 'var(--danger)', color: '#fff',
                    border: 'none', borderRadius: '10px',
                    fontWeight: 700, fontSize: '14px', cursor: 'pointer'
                  }}
                >
                  Ya, Lanjutkan
                </button>
              </div>
            </div>
          </div>
        )}

        {/* POPUP MODAL WARNING APABILA DI LUAR JAM KERJA */}
        {showOutsideHoursModal && outsideHoursData && (
          <div style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(8px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1200,
            padding: '20px'
          }}>
            <div style={{
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(245, 158, 11, 0.2)',
              borderRadius: '24px',
              padding: '32px',
              width: '100%',
              maxWidth: '460px',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              textAlign: 'center',
              animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
            }}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                marginBottom: '16px'
              }}>
                <span style={{ fontSize: '24px' }}></span>
                <h3 style={{
                  fontSize: '20px',
                  fontWeight: 800,
                  color: 'var(--text-heading)',
                  margin: 0
                }}>
                  Kelompok 2
                </h3>
              </div>

              <div style={{
                width: '80px',
                height: '80px',
                background: 'rgba(245, 158, 11, 0.1)',
                color: 'var(--warning)',
                fontSize: '36px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: '50%',
                margin: '0 auto 20px auto',
                animation: 'pulse 2s infinite'
              }}>
                
              </div>

              <h2 style={{
                fontSize: '18px',
                fontWeight: 800,
                color: 'var(--text-heading)',
                marginBottom: '12px'
              }}>
                PERHATIAN!
              </h2>

              <p style={{
                fontSize: '14px',
                color: 'var(--text-muted)',
                lineHeight: '1.6',
                marginBottom: '24px'
              }}>
                Anda sedang melakukan absensi di luar jam kerja yang ditentukan.
              </p>

              <div style={{
                background: '#f8fafc',
                border: '1px solid var(--border)',
                borderRadius: '16px',
                padding: '16px',
                marginBottom: '24px',
                textAlign: 'left'
              }}>
                <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '6px' }}>
                  <strong>Jam Kerja:</strong> {workSettings.jam_masuk_awal} - {workSettings.jam_keluar_akhir}
                </div>
                <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>
                  <strong>Waktu Sekarang:</strong> {outsideHoursData.curTime}
                </div>
              </div>

              <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-heading)', marginBottom: '24px' }}>
                Lanjutkan absensi?
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button 
                  className="btn-action btn-action-primary" 
                  style={{ flex: 1, padding: '12px', background: 'linear-gradient(135deg, #f59e0b, #d97706)' }}
                  onClick={async () => {
                    setShowOutsideHoursModal(false);
                    await executeSelfAttendance(outsideHoursData.status, outsideHoursData.curDate, outsideHoursData.curTime);
                    setOutsideHoursData(null);
                  }}
                >
                  Lanjutkan Absen 
                </button>
                <button 
                  className="btn-action btn-action-secondary" 
                  style={{ flex: 1, padding: '12px' }}
                  onClick={() => {
                    setShowOutsideHoursModal(false);
                    setOutsideHoursData(null);
                  }}
                >
                  Batal
                </button>
              </div>
            </div>
          </div>
        )}
        {(activeDetailEmployee || currentEmployee) && (
          <div className="print-only-container">
            <div style={{ textAlign: 'center', borderBottom: '2px solid #1e293b', paddingBottom: '12px', marginBottom: '20px' }}>
              <h1 style={{ fontSize: '20pt', fontWeight: 'bold', margin: '0 0 6px 0', color: 'black' }}>LAPORAN REKAP BULANAN KEHADIRAN KARYAWAN</h1>
              <p style={{ fontSize: '12pt', fontWeight: 'bold', margin: '6px 0 0 0', color: 'var(--text-heading)' }}>
                Periode: {(() => {
                  const [year, month] = selectedMonth.split('-');
                  const dateObj = new Date(parseInt(year), parseInt(month) - 1, 1);
                  return dateObj.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
                })()}
              </p>
              <p style={{ fontSize: '10pt', margin: '4px 0 0 0', color: 'var(--text-muted)' }}>Sistem Presensi Digital - PresensiHub</p>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px', fontSize: '11pt', color: 'black' }}>
              <div>
                <strong>Nama Karyawan:</strong> {activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama} <br />
                <strong>Jabatan:</strong> {activeDetailEmployee ? activeDetailEmployee.jabatan : currentEmployee?.jabatan} <br />
                <strong>Divisi:</strong> {activeDetailEmployee ? activeDetailEmployee.nama_divisi : currentEmployee?.nama_divisi || 'Tanpa Divisi'}
              </div>
              <div style={{ textAlign: 'right' }}>
                <strong>Tanggal Cetak:</strong> {new Date().toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })} <br />
                <strong>Status Dokumen:</strong> Cetak Resmi Sistem
              </div>
            </div>

            <h3 style={{ borderBottom: '1px solid #cbd5e1', paddingBottom: '6px', marginBottom: '10px', fontSize: '12pt', color: 'black' }}>Rekapitulasi Kehadiran</h3>
            <table style={{ width: '100%', marginBottom: '20px', borderCollapse: 'collapse', textAlign: 'center' }}>
              <thead>
                <tr style={{ background: '#f1f5f9' }}>
                  <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Hadir </th>
                  <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Izin </th>
                  <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Sakit </th>
                  <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Alpa </th>
                  <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Total Hari</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                    {(() => {
                      const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                      return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Hadir').length;
                    })()} Hari
                  </td>
                  <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                    {(() => {
                      const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                      return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Izin').length;
                    })()} Hari
                  </td>
                  <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                    {(() => {
                      const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                      return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Sakit').length;
                    })()} Hari
                  </td>
                  <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                    {(() => {
                      const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                      return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Alpa').length;
                    })()} Hari
                  </td>
                  <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                    {(() => {
                      const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                      return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth)).length;
                    })()} Hari
                  </td>
                </tr>
              </tbody>
            </table>

            <h3 style={{ borderBottom: '1px solid #cbd5e1', paddingBottom: '6px', marginBottom: '10px', fontSize: '12pt', color: 'black' }}>Rincian Tanggal Kehadiran</h3>
            <table className="print-table">
              <thead>
                <tr>
                  <th>No</th>
                  <th>Hari & Tanggal</th>
                  <th>Jam Masuk</th>
                  <th>Jam Keluar</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {(() => {
                  const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                  const list = absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth));
                  if (list.length === 0) {
                    return (
                      <tr>
                        <td colSpan="5" style={{ textAlign: 'center', color: 'black' }}>Tidak ada riwayat kehadiran</td>
                      </tr>
                    );
                  }
                  return list.map((a, idx) => {
                    const fDate = new Date(a.tanggal).toLocaleDateString('id-ID', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    });
                    return (
                      <tr key={a.id}>
                        <td style={{ color: 'black' }}>{idx + 1}</td>
                        <td style={{ color: 'black' }}>{fDate}</td>
                        <td style={{ color: 'black' }}>{a.status === 'Hadir' ? (a.jam_masuk ? `${a.jam_masuk.slice(0, 5)} WIB` : '-') : '-'}</td>
                        <td style={{ color: 'black' }}>{a.status === 'Hadir' ? (a.jam_keluar ? `${a.jam_keluar.slice(0, 5)} WIB` : 'Belum Scan Pulang ') : '-'}</td>
                        <td style={{ color: 'black' }}>{a.status}</td>
                      </tr>
                    );
                  });
                })()}
              </tbody>
            </table>

            <div style={{ marginTop: '50px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', fontSize: '11pt', color: 'black' }}>
              <div style={{ textAlign: 'center' }}>
                <p>Mengetahui,</p>
                <br /><br /><br />
                <p style={{ textDecoration: 'underline', fontWeight: 'bold' }}>Manager HRD</p>
              </div>
              <div style={{ textAlign: 'center' }}>
                <p>Penerima Laporan,</p>
                <br /><br /><br />
                <p style={{ textDecoration: 'underline', fontWeight: 'bold' }}>{activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // ==========================================
  // RENDER 3: ADMIN DASHBOARD
  // ==========================================
  const pendingCutiCount = cuti.filter((c) => c.status === 'Pending').length;

  return (
    <div className="app-layout">
      {/* Header */}
      <header className="app-header">
        <div className="brand">
          <div className="brand-icon">HR</div>
          <span className="brand-name">PresensiHub Admin</span>
        </div>
        <div className="header-actions">
          <div className="user-info">
            <div className="avatar">A</div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '14px', color: 'var(--text-heading)' }}>Administrator</div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Online</div>
            </div>
          </div>
          <button className="btn-outline" onClick={logout}>
            Keluar 
          </button>
        </div>
      </header>

      {/* Tabs */}
      <nav className="dashboard-nav">
        <div className={`nav-tab ${activeTab === 'pegawai' ? 'active' : ''}`} onClick={() => setActiveTab('pegawai')}>
           Kelola Pegawai
        </div>
        <div className={`nav-tab ${activeTab === 'divisi' ? 'active' : ''}`} onClick={() => setActiveTab('divisi')}>
           Kelola Divisi
        </div>
        <div className={`nav-tab ${activeTab === 'absensi' ? 'active' : ''}`} onClick={() => setActiveTab('absensi')}>
           Presensi Pegawai
        </div>
        <div className={`nav-tab ${activeTab === 'ketidakhadiran' ? 'active' : ''}`} onClick={() => setActiveTab('ketidakhadiran')}>
           Ketidakhadiran
        </div>
        <div className={`nav-tab ${activeTab === 'persetujuan-cuti' ? 'active' : ''}`} onClick={() => setActiveTab('persetujuan-cuti')}>
           Persetujuan Cuti {pendingCutiCount > 0 && (
            <span style={{
              background: 'var(--danger)',
              color: 'white',
              fontSize: '10px',
              padding: '2px 6px',
              borderRadius: '9999px',
              marginLeft: '4px',
              fontWeight: 800
            }}>
              {pendingCutiCount}
            </span>
          )}
        </div>
        <div className={`nav-tab ${activeTab === 'qr-office' ? 'active' : ''}`} onClick={() => { setActiveTab('qr-office'); checkQrEligibility(); setOfficeQrCode(''); }}>
           QR Code Kantor
        </div>
        <div className={`nav-tab ${activeTab === 'scan-checkout' ? 'active' : ''}`} onClick={() => setActiveTab('scan-checkout')}>
           Scan Absen Pulang
        </div>
        <div className={`nav-tab ${activeTab === 'settings-kerja' ? 'active' : ''}`} onClick={() => { setActiveTab('settings-kerja'); getWorkSettings(); }}>
           Pengaturan Jam Kerja
        </div>
        <div className={`nav-tab ${activeTab === 'create-user' ? 'active' : ''}`} onClick={() => setActiveTab('create-user')}>
           Pegawai Baru
        </div>
      </nav>

      <main className="app-content">
        {/* Statistics Panels */}
        <section className="stats-grid">
          <div 
            className="stat-card" 
            onClick={() => setActiveTab('pegawai')}
            style={{ cursor: 'pointer', transition: 'all 0.3s ease', }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-4px)';
              e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.12)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'var(--shadow-sm)';
            }}
            title="Klik untuk melihat daftar pegawai"
          >
            <div>
              <div className="stat-label">Total Pegawai</div>
              <div className="stat-value">{pegawai.length} Orang</div>
            </div>
            <div className="stat-icon icon-blue">PG</div>
          </div>

          <div 
            className="stat-card" 
            onClick={() => setActiveTab('divisi')}
            style={{ cursor: 'pointer', transition: 'all 0.3s ease' }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-4px)';
              e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.12)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'var(--shadow-sm)';
            }}
            title="Klik untuk melihat daftar divisi"
          >
            <div>
              <div className="stat-label">Jumlah Divisi</div>
              <div className="stat-value">{divisi.length} Bagian</div>
            </div>
            <div className="stat-icon icon-cyan">DV</div>
          </div>

          <div 
            className="stat-card" 
            onClick={() => setActiveTab('ketidakhadiran')}
            style={{ cursor: 'pointer', transition: 'all 0.3s ease' }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-4px)';
              e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.12)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'var(--shadow-sm)';
            }}
            title="Klik untuk melihat pegawai yang tidak hadir hari ini"
          >
            <div>
              <div className="stat-label">Ketidakhadiran</div>
              <div className="stat-value">{ketidakhadiran.length} Orang</div>
            </div>
            <div className="stat-icon icon-green">AB</div>
          </div>
        </section>

        {/* Tab 1: Pegawai */}
        {activeTab === 'pegawai' && (
          <div>
            {/* Hint: Untuk tambah pegawai, gunakan tab " Buat User Baru" */}
            <div style={{
              padding: '12px 16px',
              background: 'rgba(59, 130, 246, 0.08)',
              borderLeft: '3px solid var(--primary)',
              borderRadius: '8px',
              marginBottom: '20px',
              fontSize: '13px',
              color: 'var(--primary)',
              fontWeight: 600
            }}>
               Untuk membuat pegawai baru, gunakan tab <strong>" Pegawai Baru"</strong>. Tab ini hanya untuk Edit & Delete data pegawai.
            </div>

            {/* List Pegawai */}
            <div className="panel-card">
              <div className="panel-header">
                <span className="panel-title"> Daftar Pegawai Aktif</span>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <input
                    type="text"
                    className="form-input-plain"
                    placeholder=" Cari nama pegawai..."
                    value={pegawaiSearch}
                    onChange={(e) => setPegawaiSearch(e.target.value)}
                    style={{ width: '180px', padding: '6px 12px', fontSize: '13px', margin: 0 }}
                  />
                  <button className="btn-action btn-action-secondary" style={{ padding: '6px 12px' }} onClick={getPegawai}>Refresh</button>
                </div>
              </div>
              <div className="table-responsive">
                {(() => {
                  const filteredPegawai = pegawai.filter((p) =>
                    p.nama.toLowerCase().includes(pegawaiSearch.toLowerCase())
                  );
                  if (filteredPegawai.length === 0) {
                    return (
                      <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-faint)' }}>
                        Tidak ada data pegawai yang cocok.
                      </div>
                    );
                  }
                  return (
                    <table className="custom-table">
                      <thead>
                        <tr>
                          <th>Nama</th>
                          <th>Divisi</th>
                          <th>Jabatan</th>
                          <th style={{ textAlign: 'right' }}>Aksi</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredPegawai.map((p) => (
                        <tr key={p.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer' }} onClick={() => setActiveDetailEmployee(p)} title="Klik untuk detail & rekap kehadiran">
                              <div style={{
                                width: '42px',
                                height: '42px',
                                borderRadius: '50%',
                                background: p.foto ? 'transparent' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                border: '2px solid #e2e8f0',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                fontSize: '18px',
                                fontWeight: 700,
                                color: '#fff',
                                flexShrink: 0,
                                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                                transition: 'transform 0.2s',
                                overflow: 'hidden'
                              }}>
                                {p.foto ? (
                                  <img src={p.foto} alt={p.nama} style={{
                                    width: '100%',
                                    height: '100%',
                                    objectFit: 'cover',
                                    borderRadius: '50%'
                                  }} />
                                ) : (
                                  p.nama.charAt(0).toUpperCase()
                                )}
                              </div>
                              <div>
                                <div style={{ fontWeight: 700, color: 'var(--text-heading)', fontSize: '14px', marginBottom: '4px' }}>
                                  {p.nama}
                                </div>
                                <div style={{ fontSize: '12px', color: 'var(--text-faint)', fontWeight: 500 }}>PG-{p.id}</div>
                              </div>
                            </div>
                          </td>
                          <td><span className="badge badge-primary">{p.nama_divisi || 'Tanpa Divisi'}</span></td>
                          <td><strong style={{ color: 'var(--text-main)' }}>{p.jabatan}</strong></td>
                          <td style={{ textAlign: 'right' }}>
                            <div style={{ display: 'inline-flex', gap: '6px' }}>
                              <button className="btn-sm-action btn-sm-edit" onClick={() => setActiveDetailEmployee(p)}>
                                 Laporan
                              </button>
                              <button className="btn-sm-action btn-sm-edit" onClick={() => setActiveQrEmployee(p)}>
                                 Lihat QR
                              </button>
                              <button className="btn-sm-action btn-sm-delete" onClick={() => {
                                console.log("Hapus clicked for", p.id);
                                hapusPegawai(p.id);
                              }}>
                                 Hapus
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                );
              })()}
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Divisi */}
        {activeTab === 'divisi' && (
          <div className="dashboard-grid two-cols">
            <div className="panel-card">
              <div className="panel-header"><span className="panel-title"> Tambah Divisi</span></div>
              <div className="panel-body">
                <div className="dashboard-form">
                  <div>
                    <label htmlFor="d-nama">Nama Divisi</label>
                    <input
                      id="d-nama"
                      type="text"
                      className="form-input-plain"
                      placeholder="Contoh: IT"
                      value={namaDivisi}
                      onChange={(e) => setNamaDivisi(e.target.value)}
                    />
                  </div>
                  <button className="btn-action btn-action-primary" onClick={tambahDivisi}>Simpan Divisi</button>
                </div>
              </div>
            </div>

            <div className="panel-card">
              <div className="panel-header"><span className="panel-title"> Daftar Divisi</span></div>
              <div className="panel-body">
                {divisi.length === 0 ? (
                  <div style={{ textAlign: 'center', color: 'var(--text-faint)' }}>Belum ada divisi.</div>
                ) : (
                  <div className="data-grid">
                    {divisi.map((d) => {
                      const count = pegawai.filter((p) => p.divisi_id === d.id).length;
                      return (
                        <div key={d.id} className="data-card">
                          <div className="card-title">{d.nama_divisi}</div>
                          <div className="card-subtitle">DIV-{d.id}</div>
                          <div className="badge badge-secondary">{count} Pegawai</div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Absensi */}
        {activeTab === 'absensi' && (
          <div className="dashboard-grid two-cols">
            <div className="panel-card">
              <div className="panel-header"><span className="panel-title"> Catat Absensi Manual</span></div>
              <div className="panel-body">
                <div className="dashboard-form">
                  <div>
                    <label htmlFor="a-pegawai">Pegawai</label>
                    <select
                      id="a-pegawai"
                      className="form-select"
                      value={absensiPegawaiId}
                      onChange={(e) => setAbsensiPegawaiId(e.target.value)}
                    >
                      <option value="">-- Pilih Pegawai --</option>
                      {pegawai.map((p) => (
                        <option key={p.id} value={p.id}>{p.nama}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label htmlFor="a-tanggal">Tanggal</label>
                    <input id="a-tanggal" type="date" className="form-input-plain" value={absensiTanggal} onChange={(e) => setAbsensiTanggal(e.target.value)} />
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                    <div>
                      <label htmlFor="a-masuk">Masuk</label>
                      <input id="a-masuk" type="time" className="form-input-plain" value={absensiJamMasuk} onChange={(e) => setAbsensiJamMasuk(e.target.value)} />
                    </div>
                    <div>
                      <label htmlFor="a-keluar">Keluar</label>
                      <input id="a-keluar" type="time" className="form-input-plain" value={absensiJamKeluar} onChange={(e) => setAbsensiJamKeluar(e.target.value)} />
                    </div>
                  </div>
                  <div>
                    <label htmlFor="a-status">Status</label>
                    <select id="a-status" className="form-select" value={absensiStatus} onChange={(e) => setAbsensiStatus(e.target.value)}>
                      <option value="Hadir">Hadir </option>
                      <option value="Izin">Izin </option>
                      <option value="Sakit">Sakit </option>
                      <option value="Alpa">Alpa </option>
                    </select>
                  </div>
                  <button className="btn-action btn-action-primary" onClick={tambahAbsensi}>Simpan Kehadiran</button>
                </div>
              </div>
            </div>

            <div className="panel-card">
              <div className="panel-header" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span className="panel-title">📋 Rekap Absensi Pegawai</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span style={{ fontSize: '11px', color: 'var(--text-faint)' }}>Auto-refresh tiap 30 detik</span>
                  <button
                    className="btn-action btn-action-secondary"
                    onClick={async () => {
                      await Promise.all([getAbsensi(), getKetidakhadiran()]);
                    }}
                  >
                    🔄 Refresh
                  </button>
                </div>
              </div>

              {/* Toggle Mode + Filter */}
              <div style={{ marginBottom: '16px', display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>

                {/* Toggle Harian / Bulanan */}
                <div style={{
                  display: 'inline-flex',
                  background: 'var(--bg-subtle)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '3px',
                  gap: '2px',
                  flexShrink: 0
                }}>
                  <button
                    onClick={() => setRekapMode('harian')}
                    style={{
                      padding: '5px 14px',
                      borderRadius: '4px',
                      border: 'none',
                      cursor: 'pointer',
                      fontSize: '13px',
                      fontWeight: 600,
                      fontFamily: 'var(--font)',
                      background: rekapMode === 'harian' ? 'var(--primary)' : 'transparent',
                      color: rekapMode === 'harian' ? '#fff' : 'var(--text-muted)',
                      transition: 'all 0.15s'
                    }}
                  >Per Hari</button>
                  <button
                    onClick={() => setRekapMode('bulanan')}
                    style={{
                      padding: '5px 14px',
                      borderRadius: '4px',
                      border: 'none',
                      cursor: 'pointer',
                      fontSize: '13px',
                      fontWeight: 600,
                      fontFamily: 'var(--font)',
                      background: rekapMode === 'bulanan' ? 'var(--primary)' : 'transparent',
                      color: rekapMode === 'bulanan' ? '#fff' : 'var(--text-muted)',
                      transition: 'all 0.15s'
                    }}
                  >Per Bulan</button>
                </div>

                {/* Date Picker - tampil sesuai mode */}
                {rekapMode === 'harian' ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <label style={{ fontSize: '12px', fontWeight: 600, color: 'var(--text-muted)', whiteSpace: 'nowrap', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Tanggal:</label>
                    <input
                      type="date"
                      className="form-input-plain"
                      value={selectedDate}
                      onChange={(e) => setSelectedDate(e.target.value)}
                      style={{ padding: '7px 12px', fontSize: '14px', width: '180px' }}
                    />
                    {selectedDate && (
                      <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: 500 }}>
                        {new Date(selectedDate + 'T00:00:00').toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
                      </span>
                    )}
                  </div>
                ) : (
                  <select
                    className="form-select"
                    style={{ width: '200px', padding: '8px 12px', fontSize: '14px' }}
                    value={selectedMonth}
                    onChange={(e) => setSelectedMonth(e.target.value)}
                  >
                    {getMonthOptions().map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                )}

                {/* Search nama */}
                <input
                  type="text"
                  placeholder="Cari nama pegawai..."
                  value={searchAbsensi}
                  onChange={(e) => setSearchAbsensi(e.target.value)}
                  className="form-input-plain"
                  style={{ flex: 1, minWidth: '200px' }}
                />
              </div>

              {/* Summary */}
              {(() => {
                const filtered = absensi.filter(a => {
                  const matchDate = rekapMode === 'harian'
                    ? a.tanggal && a.tanggal.startsWith(selectedDate)
                    : a.tanggal && a.tanggal.startsWith(selectedMonth);
                  const matchName = a.nama && a.nama.toLowerCase().includes(searchAbsensi.toLowerCase());
                  return matchDate && matchName;
                });
                if (filtered.length === 0) return null;
                const hadir = filtered.filter(x => x.status === 'Hadir').length;
                const izin  = filtered.filter(x => x.status === 'Izin').length;
                const sakit = filtered.filter(x => x.status === 'Sakit').length;
                const alpa  = filtered.filter(x => x.status === 'Alpa').length;
                const pending = filtered.filter(x => x.status && x.status.startsWith('Pending')).length;
                return (
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '14px', padding: '12px 24px', background: 'var(--bg-subtle)', borderBottom: '1px solid var(--border)' }}>
                    <span className="badge badge-success">Hadir: {hadir}</span>
                    <span className="badge badge-warning">Izin: {izin}</span>
                    <span className="badge badge-secondary">Sakit: {sakit}</span>
                    <span className="badge badge-danger">Alpa: {alpa}</span>
                    {pending > 0 && <span className="badge badge-warning">Pending: {pending}</span>}
                    <span className="badge badge-primary">Total: {filtered.length}</span>
                  </div>
                );
              })()}

              <div className="table-responsive">
                {(() => {
                  const filtered = absensi.filter(a => {
                    const matchDate = rekapMode === 'harian'
                      ? a.tanggal && a.tanggal.startsWith(selectedDate)
                      : a.tanggal && a.tanggal.startsWith(selectedMonth);
                    const matchName = a.nama && a.nama.toLowerCase().includes(searchAbsensi.toLowerCase());
                    return matchDate && matchName;
                  });

                  if (filtered.length === 0) {
                    return (
                      <div style={{ padding: '48px', textAlign: 'center' }}>
                        <div style={{ fontWeight: 600, color: 'var(--text-heading)', marginBottom: '6px', fontSize: '15px' }}>
                          {absensi.length === 0 ? 'Belum ada data absensi.' : 'Tidak ada data untuk filter ini.'}
                        </div>
                        <div style={{ fontSize: '13px', color: 'var(--text-faint)' }}>
                          {rekapMode === 'harian'
                            ? `Tidak ada absensi pada ${new Date(selectedDate + 'T00:00:00').toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}`
                            : `Tidak ada absensi pada ${new Date(selectedMonth + '-01T00:00:00').toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}`
                          }
                        </div>
                      </div>
                    );
                  }

                  return (
                    <table className="custom-table">
                      <thead>
                        <tr>
                          <th>Pegawai</th>
                          <th>Tanggal</th>
                          <th>Jam Masuk</th>
                          <th>Jam Keluar</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filtered.map((a) => {
                          const formattedDate = new Date(a.tanggal).toLocaleDateString('id-ID', {
                            weekday: 'long', year: 'numeric', month: 'short', day: 'numeric'
                          });
                          let badgeClass = 'badge-success';
                          const isPending = a.status && a.status.startsWith('Pending');
                          if (a.status === 'Izin') badgeClass = 'badge-warning';
                          else if (a.status === 'Sakit') badgeClass = 'badge-primary';
                          else if (a.status === 'Alpa') badgeClass = 'badge-danger';
                          else if (a.status === 'Ditolak') badgeClass = 'badge-danger';
                          else if (isPending) badgeClass = 'badge-warning';

                          return (
                            <tr key={a.id} style={isPending ? { background: 'rgba(245,158,11,0.06)' } : {}}>
                              <td>
                                <div
                                  style={{ fontWeight: 700, color: 'var(--text-heading)', cursor: 'pointer', textDecoration: 'underline' }}
                                  onClick={() => setActiveAbsensiEmployee(a)}
                                  title="Klik untuk lihat detail kehadiran pegawai ini"
                                >{a.nama}</div>
                                <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>PG-{a.id}</div>
                                {isPending && a.alasan && (
                                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}> <em>{a.alasan}</em></div>
                                )}
                              </td>
                              <td>{formattedDate}</td>
                              <td>
                                <div style={{ fontWeight: 600, color: 'var(--success)' }}>
                                  {a.status === 'Hadir'
                                    ? (a.jam_masuk ? `${a.jam_masuk.slice(0, 5)} WIB` : '-')
                                    : '-'}
                                </div>
                                {a.status === 'Hadir' && a.keterangan_jam === 'Terlambat' && (
                                  <div style={{ fontSize: '11px', color: 'var(--danger)', fontWeight: 700, marginTop: '2px' }}> Terlambat</div>
                                )}
                              </td>
                              <td>
                                <div style={{ fontWeight: 600, color: 'var(--text-muted)' }}>
                                  {a.status === 'Hadir'
                                    ? (a.jam_keluar ? `${a.jam_keluar.slice(0, 5)} WIB` : 'Belum Pulang')
                                    : '-'}
                                </div>
                                {a.status === 'Hadir' && a.is_lembur == 1 && (
                                  <div style={{ fontSize: '11px', color: 'var(--warning)', fontWeight: 700, marginTop: '2px' }}> Lembur</div>
                                )}
                              </td>
                              <td>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'flex-start' }}>
                                  <span className={`badge ${badgeClass}`}>{a.status}</span>
                                  {(a.alasan || a.foto_bukti) && (
                                    <button
                                      onClick={() => {
                                        setPreviewImage(a.foto_bukti || 'NO_IMAGE');
                                        setPreviewAlasan(a.alasan || 'Tidak ada alasan.');
                                      }}
                                      style={{ padding: '3px 10px', fontSize: '11px', background: '#6366f1', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 700 }}
                                    > Detail</button>
                                  )}
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  );
                })()}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'ketidakhadiran' && (
          <div className="panel-card">
            <div className="panel-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <span className="panel-title"> Daftar Pegawai yang Tidak Hadir</span>
                <input 
                  type="date" 
                  className="form-input-plain"
                  value={ketidakhadiranDate}
                  onChange={(e) => setKetidakhadiranDate(e.target.value)}
                  style={{ padding: '6px 12px', fontSize: '13px', width: 'auto' }}
                />
              </div>
              <button className="btn-action btn-action-secondary" onClick={getKetidakhadiran}>Refresh</button>
            </div>
            <div className="table-responsive">
              {/* Banner Hari Libur */}
              {holidayInfo && holidayInfo.is_holiday ? (
                <div style={{ padding: '48px 40px', textAlign: 'center' }}>
                  <div style={{ fontSize: '64px', marginBottom: '16px' }}>
                    {holidayInfo.holiday_type === 'weekend' && '📅'}
                    {holidayInfo.holiday_type === 'future' && '⏳'}
                    {holidayInfo.holiday_type === 'ongoing' && '⚡'}
                    {!(['weekend', 'future', 'ongoing'].includes(holidayInfo.holiday_type)) && '🎉'}
                  </div>
                  <div style={{
                    display: 'inline-block',
                    padding: '6px 18px',
                    borderRadius: '20px',
                    background: holidayInfo.holiday_type === 'weekend'
                      ? 'linear-gradient(135deg, #3b82f6 0%, #6366f1 100%)'
                      : holidayInfo.holiday_type === 'future'
                      ? 'linear-gradient(135deg, #64748b 0%, #475569 100%)'
                      : holidayInfo.holiday_type === 'ongoing'
                      ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
                      : 'linear-gradient(135deg, #f59e0b 0%, #ef4444 100%)',
                    color: '#fff',
                    fontSize: '12px',
                    fontWeight: 700,
                    letterSpacing: '1px',
                    textTransform: 'uppercase',
                    marginBottom: '16px'
                  }}>
                    {holidayInfo.holiday_type === 'weekend' ? 'Akhir Pekan' : 
                     holidayInfo.holiday_type === 'future' ? 'Masa Depan' : 
                     holidayInfo.holiday_type === 'ongoing' ? 'Sesi Dibuka' : 'Hari Libur Nasional'}
                  </div>
                  <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '10px' }}>
                    {holidayInfo.holiday_name}
                  </div>
                  <div style={{ fontSize: '14px', color: 'var(--text-muted)', maxWidth: '400px', margin: '0 auto', lineHeight: 1.7 }}>
                    {holidayInfo.keterangan}
                  </div>
                  <div style={{
                    marginTop: '24px',
                    padding: '14px 24px',
                    background: holidayInfo.holiday_type === 'ongoing' ? 'rgba(16, 185, 129, 0.08)' : 'rgba(99, 102, 241, 0.08)',
                    borderRadius: '12px',
                    display: 'inline-block',
                    fontSize: '13px',
                    color: holidayInfo.holiday_type === 'ongoing' ? 'var(--success)' : 'var(--primary)',
                    fontWeight: 600
                  }}>
                     {holidayInfo.holiday_type === 'ongoing' || holidayInfo.holiday_type === 'future'
                       ? 'Data absensi & ketidakhadiran belum dihitung'
                       : 'Tidak ada data ketidakhadiran pada hari libur'}
                  </div>
                </div>
              ) : ketidakhadiran.length === 0 ? (
                <div style={{ padding: '60px 40px', textAlign: 'center' }}>
                  <div style={{ fontSize: '48px', marginBottom: '12px' }}></div>
                  <div style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-heading)', marginBottom: '8px' }}>Semua Pegawai Hadir</div>
                  <div style={{ fontSize: '14px', color: 'var(--text-faint)' }}>
                    Tidak ada pegawai yang tidak hadir pada tanggal {new Date(ketidakhadiranDate).toLocaleDateString('id-ID')}
                  </div>
                </div>
              ) : (
                <div>
                  <div style={{
                    padding: '8px 14px',
                    background: 'rgba(239, 68, 68, 0.08)',
                    borderLeft: '3px solid var(--danger)',
                    borderRadius: '8px',
                    marginBottom: '16px',
                    fontSize: '13px',
                    color: 'var(--danger)',
                    fontWeight: 600,
                    display: 'inline-block'
                  }}>
                    🚫 {ketidakhadiran.length} pegawai tidak hadir — {new Date(ketidakhadiranDate).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </div>
                  <div className="data-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '16px' }}>
                    {ketidakhadiran.map((pegawai) => (
                      <div key={pegawai.id} className="data-card" style={{
                        padding: '16px',
                        border: '2px solid rgba(239, 68, 68, 0.2)',
                        background: 'rgba(239, 68, 68, 0.05)',
                        borderRadius: '10px',
                        boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
                          <div style={{
                            width: '48px',
                            height: '48px',
                            borderRadius: '50%',
                            background: pegawai.foto ? `url(${pegawai.foto})` : 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                            backgroundSize: 'cover',
                            backgroundPosition: 'center',
                            border: '2px solid var(--danger)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '18px',
                            fontWeight: 700,
                            color: '#fff',
                            flexShrink: 0
                          }}>
                            {!pegawai.foto && pegawai.nama.charAt(0).toUpperCase()}
                          </div>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontWeight: 700, color: 'var(--text-heading)', fontSize: '14px', marginBottom: '4px' }}>
                              {pegawai.nama}
                            </div>
                            <div style={{ fontSize: '12px', color: 'var(--text-faint)' }}>PG-{pegawai.id}</div>
                          </div>
                        </div>
                        <div style={{ borderTop: '1px solid rgba(0,0,0,0.08)', paddingTop: '12px' }}>
                          <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '6px' }}>
                            <strong>Jabatan:</strong> {pegawai.jabatan}
                          </div>

                          {/* Absence summary */}
                          <div style={{ marginBottom: '8px' }}>
                            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', alignItems: 'center' }}>
                              {(pegawai.absences || []).length > 0 ? (
                                pegawai.absences.map((abs, idx) => {
                                  let badgeClass = 'badge-danger';
                                  if (abs.type === 'izin') badgeClass = 'badge-warning';
                                  else if (abs.type === 'alpa') badgeClass = 'badge-danger';
                                  else if (abs.type === 'cuti') badgeClass = 'badge-primary';

                                  const label = abs.type === 'cuti'
                                    ? `Cuti (${abs.jenis_cuti || 'Tambahan'}: ${abs.tanggal_mulai || '-'} - ${abs.tanggal_selesai || '-'})`
                                    : (abs.type === 'izin' ? `Izin (${abs.status || ''})` : (abs.type === 'alpa' ? 'Alpa' : abs.type));

                                  return (
                                    <span key={idx} className={`badge ${badgeClass}`} style={{ whiteSpace: 'nowrap' }}>
                                      {label}
                                    </span>
                                  );
                                })
                              ) : (
                                <span className="badge badge-danger">-</span>
                              )}
                            </div>
                          </div>

                          {/* Detail button */}
                          {(pegawai.absences || []).some(x => x.alasan || x.foto_bukti || x.type === 'cuti') && (
                            <button
                              className="btn-sm-action btn-sm-edit"
                              style={{ fontSize: '10px', padding: '6px 10px', background: 'rgba(99,102,241,0.12)', border: '1px solid rgba(99,102,241,0.35)', color: 'var(--primary)' }}
                              onClick={() => {
                                const cutiDetails = (pegawai.absences || []).filter(x => x.type === 'cuti');
                                const izinDetails = (pegawai.absences || []).filter(x => x.type === 'izin');
                                const alpaDetails = (pegawai.absences || []).filter(x => x.type === 'alpa');

                                const lines = [];

                                if (izinDetails.length) {
                                  izinDetails.forEach(x => {
                                    lines.push(`Izin/Sakit: ${x.status || '-'}\nAlasan: ${x.alasan || '-'}\n`);
                                  });
                                }

                                if (alpaDetails.length) {
                                  alpaDetails.forEach(x => {
                                    lines.push(`Alpa: ${x.status || '-'}\nAlasan: ${x.alasan || '-'}\n`);
                                  });
                                }

                                if (cutiDetails.length) {
                                  cutiDetails.forEach(x => {
                                    const durasi = (() => {
                                      try {
                                        if (!x.tanggal_mulai || !x.tanggal_selesai) return null;
                                        const start = new Date(x.tanggal_mulai);
                                        const end = new Date(x.tanggal_selesai);
                                        if (isNaN(start.getTime()) || isNaN(end.getTime())) return null;
                                        return Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;
                                      } catch (e) { return null; }
                                    })();
                                    lines.push(`Cuti Tambahan: ${x.jenis_cuti || '-'}\nDurasi: ${durasi ? `${durasi} hari` : '-'}\nTanggal: ${x.tanggal_mulai || '-'} - ${x.tanggal_selesai || '-'}\nAlasan: ${x.alasan || '-'}\n`);
                                  });
                                }

                                // Prefer showing cuti photo; fallback to any other photo
                                const photo = (cutiDetails[0] && cutiDetails[0].foto_bukti) || (izinDetails[0] && izinDetails[0].foto_bukti) || (alpaDetails[0] && alpaDetails[0].foto_bukti) || 'NO_IMAGE';
                                setPreviewImage(photo);
                                setPreviewAlasan(lines.join('\n').trim() || 'Tidak ada alasan.');
                              }}
                            >
                               Detail Absensi
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}


        {/* Tab 4: Persetujuan Cuti (Admin) */}
        {activeTab === 'persetujuan-cuti' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

            {/* Section: Pending Izin / Sakit */}
            {(() => {
              const pendingAbsensi = absensi.filter(a => a.status === 'Pending Izin' || a.status === 'Pending Sakit');
              // Group by: pegawai_id + status + alasan (same submission)
              const groups = [];
              const seen = new Map();
              pendingAbsensi.forEach(a => {
                const key = `${a.pegawai_id}_${a.status}_${a.alasan}`;
                if (!seen.has(key)) {
                  seen.set(key, groups.length);
                  groups.push({ key, nama: a.nama, status: a.status, alasan: a.alasan, foto_bukti: a.foto_bukti, pegawai_id: a.pegawai_id, records: [a] });
                } else {
                  groups[seen.get(key)].records.push(a);
                }
              });
              return (
                <div className="panel-card">
                  <div className="panel-header">
                    <span className="panel-title">
                       Pengajuan Izin / Sakit Menunggu Persetujuan
                      {groups.length > 0 && (
                        <span style={{
                          background: 'var(--danger)',
                          color: 'white',
                          fontSize: '10px',
                          padding: '2px 8px',
                          borderRadius: '9999px',
                          marginLeft: '8px',
                          fontWeight: 800
                        }}>{groups.length}</span>
                      )}
                    </span>
                    <button className="btn-action btn-action-secondary" onClick={getAbsensi}>Refresh</button>
                  </div>
                  <div className="table-responsive">
                    {groups.length === 0 ? (
                      <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-faint)' }}>
                         Tidak ada pengajuan Izin/Sakit yang menunggu persetujuan.
                      </div>
                    ) : (
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Karyawan</th>
                            <th>Jenis</th>
                            <th>Durasi</th>
                            <th>Periode</th>
                            <th>Alasan</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {groups.map((g) => {
                            const isPendingIzin = g.status === 'Pending Izin';
                            const sortedDates = g.records.map(r => r.tanggal).sort();
                            const firstDate = sortedDates[0];
                            const lastDate = sortedDates[sortedDates.length - 1];
                            const fFirst = new Date(firstDate).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
                            const fLast = new Date(lastDate).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
                            const durasi = g.records.length;
                            return (
                              <tr key={g.key} style={{ background: 'rgba(245, 158, 11, 0.05)' }}>
                                <td>
                                  <div style={{ fontWeight: 700, color: 'var(--text-heading)' }}>{g.nama}</div>
                                </td>
                                <td>
                                  <span className={`badge ${isPendingIzin ? 'badge-warning' : 'badge-primary'}`}>
                                    {isPendingIzin ? '🏠 Izin' : '🏥 Sakit'}
                                  </span>
                                </td>
                                <td>
                                  <span style={{ fontWeight: 700, color: 'var(--primary)', fontSize: '15px' }}>{durasi}</span>
                                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', marginLeft: '3px' }}>hari</span>
                                </td>
                                <td style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                                  {firstDate === lastDate ? fFirst : `${fFirst} – ${fLast}`}
                                </td>
                                <td>
                                  <div style={{ maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontStyle: 'italic', color: 'var(--text-muted)', fontSize: '12px' }} title={g.alasan}>
                                    {g.alasan || '-'}
                                  </div>
                                </td>
                                <td>
                                  <button
                                    type="button"
                                    style={{ 
                                      cursor: 'pointer', 
                                      border: 'none',
                                      fontWeight: 700,
                                      fontSize: '12px',
                                      padding: '6px 12px',
                                      borderRadius: '6px',
                                      transition: 'all 0.2s ease',
                                      backgroundColor: '#f59e0b',
                                      color: 'white',
                                      pointerEvents: 'auto',
                                      display: 'block'
                                    }}
                                    onClick={(e) => {
                                      e.preventDefault();
                                      e.stopPropagation();
                                      console.log('[DEBUG] Status badge clicked:', g.nama, g.status);
                                      openApprovalModal('izin', {
                                        nama: g.nama,
                                        status: g.status,
                                        alasan: g.alasan,
                                        foto_bukti: g.foto_bukti,
                                        pegawai_id: g.pegawai_id,
                                        durasi,
                                        firstDate,
                                        lastDate
                                      });
                                    }}
                                    onMouseEnter={(e) => {
                                      e.target.style.backgroundColor = '#d97706';
                                      e.target.style.transform = 'scale(1.05)';
                                      e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                                    }}
                                    onMouseLeave={(e) => {
                                      e.target.style.backgroundColor = '#f59e0b';
                                      e.target.style.transform = 'scale(1)';
                                      e.target.style.boxShadow = 'none';
                                    }}
                                    title="Klik untuk ACC/Tolak"
                                  >
                                    {g.status}
                                  </button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    )}
                  </div>
                </div>
              );
            })()}

            {/* Section: Cuti Tambahan */}
            <div className="panel-card">
            <div className="panel-header">
              <span className="panel-title"> Daftar Pengajuan Cuti Tambahan Karyawan</span>
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <button className="btn-action btn-action-secondary" onClick={getCuti}>Refresh</button>
                {selectedCutiIds.size > 0 && (
                  <button 
                    className="btn-action btn-action-primary"
                    style={{ background: 'linear-gradient(135deg, #10b981, #059669)', fontWeight: 700 }}
                    onClick={approveMultipleCuti}
                  >
                    ✅ ACC {selectedCutiIds.size}
                  </button>
                )}
              </div>
            </div>

            {/* Filter & Sort Controls */}
            {cuti.length > 0 && (
              <div style={{ padding: '16px', background: '#f8fafc', borderRadius: '12px', marginBottom: '16px', display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
                <div>
                  <label style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>Filter:</label>
                  <select 
                    value={cutiFilterBy}
                    onChange={(e) => setCutiFilterBy(e.target.value)}
                    style={{ marginLeft: '6px', padding: '6px 10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '12px', fontWeight: 500 }}
                  >
                    <option value="semua">Semua Status</option>
                    <option value="pending">Pending Saja</option>
                    <option value="1-3hari">1-3 Hari</option>
                    <option value="4-7hari">4-7 Hari</option>
                    <option value="7plus">7+ Hari</option>
                  </select>
                </div>
                <div>
                  <label style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>Sort:</label>
                  <select 
                    value={cutiSortBy}
                    onChange={(e) => setCutiSortBy(e.target.value)}
                    style={{ marginLeft: '6px', padding: '6px 10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '12px', fontWeight: 500 }}
                  >
                    <option value="terbaru">Terbaru</option>
                    <option value="durasi_lama">Durasi Terlama</option>
                    <option value="durasi_pendek">Durasi Terpendek</option>
                  </select>
                </div>
              </div>
            )}

            <div className="table-responsive">
              {cuti.length === 0 ? (
                <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-faint)' }}>
                  Tidak ada data pengajuan cuti tambahan saat ini.
                </div>
              ) : (
                (() => {
                  // Apply filter
                  let filtered = cuti.filter(c => {
                    if (cutiFilterBy === 'pending') return c.status === 'Pending';
                    if (cutiFilterBy === '1-3hari') return c.durasi_hari >= 1 && c.durasi_hari <= 3;
                    if (cutiFilterBy === '4-7hari') return c.durasi_hari >= 4 && c.durasi_hari <= 7;
                    if (cutiFilterBy === '7plus') return c.durasi_hari > 7;
                    return true;
                  });

                  // Apply sort
                  if (cutiSortBy === 'terbaru') {
                    filtered.sort((a, b) => new Date(b.tanggal_pengajuan) - new Date(a.tanggal_pengajuan));
                  } else if (cutiSortBy === 'durasi_lama') {
                    filtered.sort((a, b) => b.durasi_hari - a.durasi_hari);
                  } else if (cutiSortBy === 'durasi_pendek') {
                    filtered.sort((a, b) => a.durasi_hari - b.durasi_hari);
                  }

                  return (
                    <table className="custom-table">
                      <thead>
                        <tr>
                          <th style={{ width: '40px' }}>
                            <input 
                              type="checkbox"
                              onChange={() => toggleSelectAllCuti(filtered)}
                              checked={filtered.filter(c => c.status === 'Pending').length > 0 && filtered.filter(c => c.status === 'Pending').every(c => selectedCutiIds.has(c.id))}
                              style={{ cursor: 'pointer' }}
                            />
                          </th>
                          <th>Karyawan</th>
                          <th>Divisi</th>
                          <th>Tanggal Pengajuan</th>
                          <th>Alasan</th>
                          <th>Durasi</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filtered.map((c) => {
                          const fDate = new Date(c.tanggal_pengajuan).toLocaleDateString('id-ID', {
                            weekday: 'long',
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric'
                          });
                          let badgeClass = 'badge-warning';
                          if (c.status === 'Disetujui') badgeClass = 'badge-success';
                          else if (c.status === 'Ditolak') badgeClass = 'badge-danger';

                          return (
                            <tr key={c.id} style={{ opacity: selectedCutiIds.has(c.id) ? 0.7 : 1, background: selectedCutiIds.has(c.id) ? 'rgba(99,102,241,0.05)' : 'transparent' }}>
                              <td>
                                {c.status === 'Pending' && (
                                  <input 
                                    type="checkbox"
                                    checked={selectedCutiIds.has(c.id)}
                                    onChange={() => toggleCutiCheckbox(c.id)}
                                    style={{ cursor: 'pointer' }}
                                  />
                                )}
                              </td>
                              <td>
                                <div style={{ fontWeight: 700, color: 'var(--text-heading)' }}>{c.nama}</div>
                                <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Req #{c.id}</div>
                              </td>
                              <td>
                                <span className="badge badge-primary">{c.nama_divisi || 'Tanpa Divisi'}</span>
                              </td>
                              <td>{fDate}</td>
                              <td>
                                <div style={{ fontSize: '13px', fontWeight: 700, color: 'var(--primary)' }}>{c.keperluan || 'Cuti Tambahan'}</div>
                                {c.tanggal_mulai && (
                                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: 600 }}>
                                    {new Date(c.tanggal_mulai).toLocaleDateString('id-ID', { month: 'short', day: 'numeric' })} - {new Date(c.tanggal_selesai).toLocaleDateString('id-ID', { month: 'short', day: 'numeric', year: 'numeric' })}
                                  </div>
                                )}
                                <div style={{ maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontStyle: 'italic', marginTop: '4px' }} title={c.alasan}>
                                  {c.alasan}
                                </div>
                              </td>
                              <td>
                                <div style={{ fontSize: '16px', fontWeight: 800, color: '#6366f1' }}>
                                  {c.durasi_hari}<span style={{ fontSize: '11px', fontWeight: 600, color: '#64748b', marginLeft: '2px' }}>H</span>
                                </div>
                              </td>
                              <td>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'flex-start' }}>
                                  {c.status === 'Pending' ? (
                                    <button
                                      className={`badge ${badgeClass}`}
                                      style={{ 
                                        cursor: 'pointer', 
                                        border: 'none',
                                        fontWeight: 700,
                                        fontSize: '12px',
                                        padding: '6px 10px',
                                        transition: 'transform 0.2s, box-shadow 0.2s'
                                      }}
                                      onClick={() => openApprovalModal('cuti', {
                                        id: c.id,
                                        nama: c.nama,
                                        keperluan: c.keperluan,
                                        alasan: c.alasan,
                                        foto_bukti: c.foto_bukti,
                                        durasi_hari: c.durasi_hari,
                                        tanggal_mulai: c.tanggal_mulai,
                                        tanggal_selesai: c.tanggal_selesai,
                                        nama_divisi: c.nama_divisi
                                      })}
                                      onMouseEnter={(e) => {
                                        e.target.style.transform = 'scale(1.05)';
                                        e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                                      }}
                                      onMouseLeave={(e) => {
                                        e.target.style.transform = 'scale(1)';
                                        e.target.style.boxShadow = 'none';
                                      }}
                                      title="Klik untuk ACC/Tolak"
                                    >
                                      {c.status}
                                    </button>
                                  ) : (
                                    <span className={`badge ${badgeClass}`}>{c.status}</span>
                                  )}
                                  {(c.alasan || c.foto_bukti) && (
                                    <button
                                      className="btn-sm-action btn-sm-edit"
                                      style={{ fontSize: '10px', padding: '2px 6px' }}
                                      onClick={() => {
                                        setPreviewImage(c.foto_bukti || 'NO_IMAGE');
                                        setPreviewAlasan(c.alasan || 'Tidak ada alasan.');
                                      }}
                                    >
                                       Detail
                                    </button>
                                  )}
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  );
                })()
              )}
            </div>
          </div>
          </div>
        )}

        {/* Tab 5: QR Code Kantor (Admin) */}
        {activeTab === 'qr-office' && (
          <div className="panel-card" style={{ maxWidth: '500px', margin: '0 auto' }}>
            <div className="panel-header">
              <span className="panel-title"> Generator QR Code Presensi Kantor</span>
              <button className="btn-action btn-action-secondary" onClick={checkQrEligibility}> Cek Ulang Status</button>
            </div>
            <div className="panel-body" style={{ textAlign: 'center', padding: '24px' }}>
              {qrEligibility.loading ? (
                <div style={{ padding: '20px', color: 'var(--text-muted)' }}>Mengecek kelayakan hari kerja & tanggal merah...</div>
              ) : (
                <div>
                  <div style={{
                    padding: '16px',
                    borderRadius: '12px',
                    background: qrEligibility.eligible ? 'rgba(16, 185, 129, 0.08)' : 'rgba(239, 68, 68, 0.08)',
                    color: qrEligibility.eligible ? 'var(--success)' : 'var(--danger)',
                    border: qrEligibility.eligible ? '1px solid rgba(16, 185, 129, 0.2)' : '1px solid rgba(239, 68, 68, 0.2)',
                    marginBottom: '24px',
                    fontSize: '14px',
                    fontWeight: 600
                  }}>
                    <span>{qrEligibility.eligible ? ' Hari ini Layak untuk Presensi' : ' Hari ini Tidak Layak untuk Presensi'}</span>
                    <div style={{ fontSize: '12px', fontWeight: 500, color: 'var(--text-muted)', marginTop: '4px' }}>
                      Status: {qrEligibility.reason} ({qrEligibility.date || todayStr})
                    </div>
                  </div>

                  <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '24px', lineHeight: '1.6' }}>
                    Sesuai ketentuan, QR Code presensi hanya dapat dibuat pada hari kerja (Senin s.d. Jumat) dan tidak berlaku pada hari libur nasional (tanggal merah) atau akhir pekan.
                  </p>

                  {qrEligibility.eligible ? (
                    <div>
                      {officeQrCode ? (
                        <div style={{ background: 'white', display: 'inline-block', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-color)', boxShadow: 'var(--shadow-md)', marginBottom: '20px' }}>
                          <img src={officeQrCode} alt="Office QR Code" style={{ width: '240px', height: '240px', display: 'block', margin: '0 auto' }} />
                          <div style={{ fontSize: '13px', fontWeight: 700, color: 'var(--primary)', marginTop: '12px' }}>
                            Scan QR untuk Presensi Hari Ini
                          </div>
                          <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                            Tanggal: {qrEligibility.date}
                          </div>
                        </div>
                      ) : (
                        <button className="btn-primary" style={{ margin: '0 auto', display: 'block' }} onClick={generateOfficeQr}>
                           Buat QR Code Hari Ini
                        </button>
                      )}
                    </div>
                  ) : (
                    <button className="btn-primary" style={{ margin: '0 auto', display: 'block', opacity: 0.5, cursor: 'not-allowed' }} disabled>
                       Tombol Terkunci (Bukan Hari Kerja/Tanggal Merah)
                    </button>
                  )}
                </div>
              )}
            </div>
          </div>
        )}


        {/* Tab: Scan Checkout */}
        {activeTab === 'scan-checkout' && (
          <div className="panel-card" style={{ maxWidth: '700px', margin: '0 auto' }}>
            <div className="panel-header">
              <span className="panel-title"> Scan Absen Pulang (Checkout)</span>
            </div>
            <div className="panel-body" style={{ textAlign: 'center' }}>
              <p style={{ fontSize: '14px', color: 'var(--text-muted)', marginBottom: '24px' }}>
                Scan QR Code ID Card Pegawai untuk mencatat jam pulang mereka.
              </p>

              {isQrScannerOpen ? (
                <div style={{ width: '100%', maxWidth: '400px', margin: '0 auto' }}>
                  <div style={{ marginBottom: '12px' }}>
                    <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: 600, fontStyle: 'italic' }}>
                       Arahkan kamera ke QR Code ID Card Pegawai
                    </p>
                  </div>
                  <div id="admin-scanner" style={{ 
                    width: '100%', 
                    height: '340px',
                    borderRadius: '12px', 
                    overflow: 'hidden', 
                    background: '#1a1a1a',
                    border: '2px solid var(--primary)',
                    display: 'block'
                  }} />
                  <button
                    className="btn-action btn-action-secondary"
                    style={{ 
                      width: '100%', 
                      marginTop: '16px',
                      padding: '12px 16px',
                      fontSize: '14px',
                      fontWeight: '600',
                      borderRadius: '8px',
                      background: 'var(--danger)',
                      color: 'white',
                      border: 'none',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease',
                      boxShadow: '0 2px 8px rgba(239, 68, 68, 0.3)'
                    }}
                    onMouseOver={(e) => e.target.style.background = '#dc2626'}
                    onMouseOut={(e) => e.target.style.background = '#ef4444'}
                    onClick={async () => { 
                      try {
                        if (window.adminScanner) {
                          try {
                            await window.adminScanner.clear();
                          } catch (err) {
                            console.error('Error stopping scanner:', err);
                          }
                          window.adminScanner = null;
                        }
                        document.querySelectorAll('video').forEach((video) => {
                          if (video.srcObject) {
                            const tracks = video.srcObject.getTracks();
                            tracks.forEach((track) => track.stop());
                            video.srcObject = null;
                          }
                        });
                      } catch (err) {
                        console.error('Error in close handler:', err);
                      }
                      setIsQrScannerOpen(false);
                    }}
                  >
                     Hentikan Scanner
                  </button>
                </div>
              ) : (
                <div>
                  <button 
                    className="btn-primary" 
                    style={{ 
                      margin: '0 auto', 
                      maxWidth: '280px', 
                      display: 'block',
                      padding: '14px 28px',
                      fontSize: '16px',
                      fontWeight: '600',
                      borderRadius: '8px',
                      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                      color: 'white',
                      border: 'none',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease',
                      boxShadow: '0 4px 12px rgba(16, 185, 129, 0.3)'
                    }}
                    onMouseOver={(e) => e.target.style.boxShadow = '0 6px 16px rgba(16, 185, 129, 0.4)'}
                    onMouseOut={(e) => e.target.style.boxShadow = '0 4px 12px rgba(16, 185, 129, 0.3)'}
                    onClick={() => { 
                      stopAllCameraStreams(); 
                      setTimeout(() => setIsQrScannerOpen(true), 100); 
                    }}
                  >
                     Buka Scanner Checkout
                  </button>
                  
                  <div style={{ 
                    marginTop: '32px',
                    padding: '16px', 
                    background: 'rgba(59, 130, 246, 0.08)',
                    border: '1px solid rgba(59, 130, 246, 0.2)',
                    borderRadius: '12px',
                    textAlign: 'left'
                  }}>
                    <h4 style={{ fontSize: '13px', fontWeight: 700, color: '#1e60c0', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                       Petunjuk Scan Checkout
                    </h4>
                    <ol style={{ fontSize: '13px', color: 'var(--text-heading)', margin: 0, paddingLeft: '20px', lineHeight: '1.8' }}>
                      <li>Klik tombol "Buka Scanner Checkout"</li>
                      <li>Minta pegawai menunjukkan QR Code ID Card mereka</li>
                      <li>Arahkan kamera ke QR Code tersebut</li>
                      <li>Sistem otomatis akan mencatat jam pulang</li>
                      <li>Konfirmasi akan muncul saat checkout berhasil</li>
                    </ol>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Tab: Work Hours Settings */}
        {activeTab === 'settings-kerja' && (
          <div className="panel-card" style={{ maxWidth: '700px', margin: '0 auto' }}>
            <div className="panel-header">
              <span className="panel-title"> Pengaturan Jam Kerja</span>
              {!editingWorkSettings && (
                <button 
                  className="btn-action btn-action-primary"
                  onClick={() => {
                    setEditingWorkSettings(true);
                    setTempWorkSettings({ ...workSettings });
                  }}
                  style={{ fontSize: '13px', padding: '8px 16px' }}
                >
                   Edit
                </button>
              )}
            </div>
            <div className="panel-body">
              {editingWorkSettings ? (
                <div>
                  <p style={{ fontSize: '13px', color: 'var(--text-faint)', marginBottom: '20px' }}>
                    Atur jam kerja yang berlaku untuk semua pegawai. Format: HH:MM (contoh: 08:00)
                  </p>
                  
                  <div className="form-group">
                    <label className="form-label">Jam Masuk Awal</label>
                    <input
                      type="time"
                      className="form-input"
                      value={tempWorkSettings.jam_masuk_awal}
                      onChange={(e) => setTempWorkSettings({ ...tempWorkSettings, jam_masuk_awal: e.target.value })}
                    />
                    <small style={{ color: 'var(--text-faint)' }}>Waktu mulai pegawai boleh absen masuk</small>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Jam Masuk Akhir</label>
                    <input
                      type="time"
                      className="form-input"
                      value={tempWorkSettings.jam_masuk_akhir}
                      onChange={(e) => setTempWorkSettings({ ...tempWorkSettings, jam_masuk_akhir: e.target.value })}
                    />
                    <small style={{ color: 'var(--text-faint)' }}>Waktu akhir pegawai boleh absen masuk (setelah ini warning)</small>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Jam Keluar Awal</label>
                    <input
                      type="time"
                      className="form-input"
                      value={tempWorkSettings.jam_keluar_awal}
                      onChange={(e) => setTempWorkSettings({ ...tempWorkSettings, jam_keluar_awal: e.target.value })}
                    />
                    <small style={{ color: 'var(--text-faint)' }}>Waktu mulai pegawai boleh absen pulang</small>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Jam Keluar Akhir</label>
                    <input
                      type="time"
                      className="form-input"
                      value={tempWorkSettings.jam_keluar_akhir}
                      onChange={(e) => setTempWorkSettings({ ...tempWorkSettings, jam_keluar_akhir: e.target.value })}
                    />
                    <small style={{ color: 'var(--text-faint)' }}>Waktu akhir pegawai boleh absen pulang (setelah ini warning)</small>
                  </div>

                  <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                    <button
                      className="btn-primary"
                      style={{ flex: 1 }}
                      onClick={updateWorkSettings}
                    >
                       Simpan Perubahan
                    </button>
                    <button
                      className="btn-action btn-action-secondary"
                      style={{ flex: 1 }}
                      onClick={() => {
                        setEditingWorkSettings(false);
                        setTempWorkSettings({ ...workSettings });
                      }}
                    >
                       Batal
                    </button>
                  </div>
                </div>
              ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '24px' }}>
                  <div style={{ 
                    background: 'rgba(59, 130, 246, 0.08)',
                    padding: '20px',
                    borderRadius: '12px',
                    border: '1px solid rgba(59, 130, 246, 0.2)'
                  }}>
                    <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, marginBottom: '8px', textTransform: 'uppercase' }}>
                       Jam Masuk
                    </div>
                    <div style={{ fontSize: '24px', fontWeight: 700, color: '#1e60c0', marginBottom: '4px' }}>
                      {workSettings.jam_masuk_awal} - {workSettings.jam_masuk_akhir}
                    </div>
                    <small style={{ color: 'var(--text-main)' }}>Waktu yang diperbolehkan absen masuk</small>
                  </div>

                  <div style={{ 
                    background: 'rgba(16, 185, 129, 0.08)',
                    padding: '20px',
                    borderRadius: '12px',
                    border: '1px solid rgba(16, 185, 129, 0.2)'
                  }}>
                    <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, marginBottom: '8px', textTransform: 'uppercase' }}>
                       Jam Keluar
                    </div>
                    <div style={{ fontSize: '24px', fontWeight: 700, color: '#059669', marginBottom: '4px' }}>
                      {workSettings.jam_keluar_awal} - {workSettings.jam_keluar_akhir}
                    </div>
                    <small style={{ color: 'var(--text-main)' }}>Waktu yang diperbolehkan absen pulang</small>
                  </div>
                </div>
              )}

              <div style={{ 
                marginTop: '24px',
                background: '#f8fafc',
                padding: '16px',
                borderRadius: '12px',
                border: '1px solid var(--border)',
                fontSize: '13px',
                color: 'var(--text-main)',
                lineHeight: '1.6'
              }}>
                <strong style={{ color: 'var(--text-heading)', display: 'block', marginBottom: '8px' }}> Informasi:</strong>
                <ul style={{ margin: 0, paddingLeft: '20px' }}>
                  <li>Pegawai akan mendapat <strong>warning</strong> jika absen di luar jam yang ditentukan</li>
                  <li>Pembatasan jam berlaku untuk semua pegawai di sistem</li>
                  <li>Jika pegawai lanjutkan absen di luar jam, tetap akan tercatat</li>
                  <li>Perubahan akan berlaku <strong>segera</strong> untuk semua pengguna</li>
                </ul>
              </div>
            </div>
          </div>
        )}

        {/* Tab: Create User */}
        {activeTab === 'create-user' && (
          <div className="panel-card" style={{ maxWidth: '600px', margin: '0 auto' }}>
            <div className="panel-header">
              <span className="panel-title"> Buat Akun User Baru</span>
            </div>
            <div className="panel-body">
              <div className="form-group">
                <label className="form-label">Username *</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Masukkan username"
                  value={newUserUsername}
                  onChange={(e) => setNewUserUsername(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Nama Lengkap *</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Masukkan nama lengkap"
                  value={newUserNama}
                  onChange={(e) => setNewUserNama(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Password *</label>
                <div className="input-container">
                  <input
                    type={showTambahPass ? 'text' : 'password'}
                    className="form-input"
                    placeholder="Masukkan password (minimal 6 karakter)"
                    value={newUserPassword}
                    onChange={(e) => setNewUserPassword(e.target.value)}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowTambahPass(!showTambahPass)}
                    title={showTambahPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showTambahPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Konfirmasi Password *</label>
                <div className="input-container">
                  <input
                    type={showTambahConfirmPass ? 'text' : 'password'}
                    className="form-input"
                    placeholder="Ulangi password"
                    value={newUserConfirmPassword}
                    onChange={(e) => setNewUserConfirmPassword(e.target.value)}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowTambahConfirmPass(!showTambahConfirmPass)}
                    title={showTambahConfirmPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showTambahConfirmPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Divisi</label>
                <select
                  className="form-input"
                  value={newUserDivisiId}
                  onChange={(e) => setNewUserDivisiId(e.target.value)}
                >
                  <option value="">-- Pilih Divisi --</option>
                  {divisi.map(d => (
                    <option key={d.id} value={d.id}>{d.nama_divisi}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Jabatan</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Masukkan jabatan (opsional)"
                  value={newUserJabatan}
                  onChange={(e) => setNewUserJabatan(e.target.value)}
                />
              </div>

              <button 
                className="btn-primary" 
                onClick={createNewUser}
                disabled={isCreatingUser}
                style={{ width: '100%' }}
              >
                {isCreatingUser ? ' Membuat...' : ' Buat User'}
              </button>
            </div>
          </div>
        )}
      </main>

      {/* ==========================================
          MODAL DOCK: GENERATE QR PEGAWAI (ADMIN)
          ========================================== */}
      {activeQrEmployee && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div className="panel-card" style={{ width: '100%', maxWidth: '400px', textAlign: 'center', animation: 'slideUp 0.3s' }}>
            <div className="panel-header">
              <span className="panel-title"> QR Code ID Pegawai</span>
              <button className="btn-sm-action" onClick={() => setActiveQrEmployee(null)}></button>
            </div>
            <div className="panel-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '16px' }}>
              <h2 style={{ fontSize: '20px', color: 'var(--text-heading)', marginBottom: '0' }}>{activeQrEmployee.nama}</h2>
              <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginTop: '0' }}>
                {activeQrEmployee.nama_divisi || 'Tanpa Divisi'} - {activeQrEmployee.jabatan}
              </p>

              {adminQrSrc ? (
                <div style={{ background: 'white', padding: '16px', borderRadius: '16px', border: '1px solid var(--border-color)', boxShadow: 'var(--shadow-sm)' }}>
                  <img src={adminQrSrc} alt="Employee QR Code" style={{ display: 'block' }} />
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: 700, marginTop: '8px', display: 'block' }}>
                    PG-QR-{activeQrEmployee.id}
                  </span>
                </div>
              ) : (
                <p>Generating QR Code...</p>
              )}

              <div style={{ display: 'flex', gap: '10px', width: '100%', marginTop: '10px' }}>
                <button className="btn-action btn-action-primary" style={{ flex: 1 }} onClick={() => setActiveQrEmployee(null)}>
                  Tutup
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL DOCK: DETAIL & REKAP ABSENSI PEGAWAI (ADMIN)
          ========================================== */}
      {activeDetailEmployee && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div className="panel-card" style={{ width: '100%', maxWidth: '650px', maxHeight: '90vh', overflowY: 'auto', animation: 'slideUp 0.3s' }}>
            <div className="panel-header">
              <span className="panel-title"> Detail & Rekap Presensi Karyawan</span>
              <button className="btn-sm-action no-print" onClick={() => setActiveDetailEmployee(null)}></button>
            </div>
            
            <div className="panel-body">
              {/* Employee Summary Card */}
              <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '12px', marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h3 style={{ fontSize: '18px', color: 'var(--text-heading)', marginBottom: '4px' }}>{activeDetailEmployee.nama}</h3>
                  <p style={{ color: 'var(--text-muted)', fontSize: '13px', margin: 0 }}>
                    Divisi: <span className="badge badge-primary">{activeDetailEmployee.nama_divisi || 'Tanpa Divisi'}</span> | Jabatan: <strong>{activeDetailEmployee.jabatan}</strong>
                  </p>
                </div>
                <div>
                  {activeDetailEmployee.foto ? (
                    <img src={activeDetailEmployee.foto} alt={activeDetailEmployee.nama} style={{ width: '60px', height: '60px', borderRadius: '50%', objectFit: 'cover', border: '3px solid #3b82f6' }} />
                  ) : (
                    <div style={{ fontSize: '48px' }}></div>
                  )}
                </div>
              </div>

              {/* Employee Full Data */}
              <h4 style={{ fontSize: '14px', color: 'var(--text-main)', marginBottom: '12px', fontWeight: 700 }}> Data Lengkap Pegawai</h4>
              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '8px', marginBottom: '24px', border: '1px solid var(--border)' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>ID Pegawai:</span> {activeDetailEmployee.id}
                  </div>
                  <div>
                    <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>Nama:</span> {activeDetailEmployee.nama}
                  </div>
                  <div>
                    <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>Jabatan:</span> {activeDetailEmployee.jabatan || 'Karyawan'}
                  </div>
                  <div>
                    <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>Divisi:</span> {activeDetailEmployee.nama_divisi || 'Tanpa Divisi'}
                  </div>
                </div>
              </div>

              {/* Rekap Grid Stats */}
              <h4 style={{ fontSize: '14px', color: 'var(--text-main)', marginBottom: '12px', fontWeight: 700 }}>Rekap Kehadiran</h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '24px' }}>
                <div style={{ background: 'rgba(16, 185, 129, 0.08)', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', color: 'var(--success)', fontWeight: 700, textTransform: 'uppercase' }}>Hadir</div>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--success)', marginTop: '4px' }}>
                    {absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Hadir').length} Hari
                  </div>
                </div>
                <div style={{ background: 'rgba(245, 158, 11, 0.08)', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', color: 'var(--warning)', fontWeight: 700, textTransform: 'uppercase' }}>Izin/Sakit</div>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--warning)', marginTop: '4px' }}>
                    {absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth) && (a.status === 'Izin' || a.status === 'Sakit')).length} Hari
                  </div>
                </div>
                <div style={{ background: 'rgba(239, 68, 68, 0.08)', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', color: 'var(--danger)', fontWeight: 700, textTransform: 'uppercase' }}>Alpa</div>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--danger)', marginTop: '4px' }}>
                    {absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Alpa').length} Hari
                  </div>
                </div>
                <div style={{ background: 'rgba(220, 38, 38, 0.08)', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', color: '#dc2626', fontWeight: 700, textTransform: 'uppercase' }}>Terlambat</div>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: '#dc2626', marginTop: '4px' }}>
                    {absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.keterangan_jam === 'Terlambat').length} Hari
                  </div>
                </div>
                <div style={{ background: 'rgba(124, 58, 237, 0.08)', padding: '12px', borderRadius: '8px', textAlign: 'center' }}>
                  <div style={{ fontSize: '11px', color: '#7c3aed', fontWeight: 700, textTransform: 'uppercase' }}>Lembur</div>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: '#7c3aed', marginTop: '4px' }}>
                    {absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.is_lembur == 1).length} Hari
                  </div>
                </div>
              </div>

              {/* Attendance Log Table */}
              <h4 style={{ fontSize: '14px', color: 'var(--text-main)', marginBottom: '12px', fontWeight: 700 }}>Log Aktivitas Absensi</h4>
              <div className="table-responsive" style={{ maxHeight: '250px', overflowY: 'auto', border: '1px solid var(--border-color)', borderRadius: '8px' }}>
                <table className="custom-table">
                  <thead>
                    <tr>
                      <th>Tanggal</th>
                      <th>Masuk</th>
                      <th>Keluar</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(() => {
                      const list = absensi.filter((a) => a.nama.toLowerCase() === activeDetailEmployee.nama.toLowerCase() && a.tanggal.startsWith(selectedMonth));
                      if (list.length === 0) {
                        return (
                          <tr>
                            <td colSpan="4" style={{ textAlign: 'center', padding: '20px', color: 'var(--text-faint)' }}>
                              Belum ada catatan absensi untuk karyawan ini.
                            </td>
                          </tr>
                        );
                      }
                      return list.map((a) => {
                        const fDate = new Date(a.tanggal).toLocaleDateString('id-ID', {
                          weekday: 'long',
                          year: 'numeric',
                          month: 'short',
                          day: 'numeric'
                        });
                        let badgeClass = 'badge-success';
                        if (a.status === 'Izin') badgeClass = 'badge-warning';
                        else if (a.status === 'Sakit') badgeClass = 'badge-primary';
                        else if (a.status === 'Alpa') badgeClass = 'badge-danger';
                        
                        return (
                          <tr key={a.id}>
                            <td>
                              <div style={{ fontWeight: 600 }}>{fDate}</div>
                            </td>
                            <td>
                              <strong style={{ color: 'var(--success)' }}>{a.jam_masuk ? `${a.jam_masuk.slice(0, 5)} WIB` : '-'}</strong>
                              {a.keterangan_jam === 'Terlambat' && (
                                <div style={{ fontSize: '11px', color: '#dc2626', fontWeight: 700, marginTop: '2px' }}>⚠ Terlambat</div>
                              )}
                            </td>
                            <td>
                              <strong style={{ color: a.jam_keluar ? '#64748b' : '#f59e0b' }}>{a.jam_keluar ? `${a.jam_keluar.slice(0, 5)} WIB` : 'Belum Scan Pulang '}</strong>
                              {a.is_lembur == 1 && (
                                <div style={{ fontSize: '11px', color: '#7c3aed', fontWeight: 700, marginTop: '2px' }}>⏰ Lembur</div>
                              )}
                            </td>
                            <td><span className={`badge ${badgeClass}`}>{a.status}</span></td>
                          </tr>
                        );
                      });
                    })()}
                  </tbody>
                </table>
              </div>

              {/* Printing Options */}
              <div className="no-print" style={{ display: 'flex', gap: '12px', marginTop: '24px', justifyContent: 'flex-end' }}>
                <button className="btn-action btn-action-secondary" onClick={() => setActiveDetailEmployee(null)}>
                  Tutup
                </button>
                <button className="btn-action btn-action-secondary" onClick={() => setShowLoginModal(activeDetailEmployee)}>
                   Lihat Password
                </button>
                <button className="btn-action btn-action-secondary" onClick={() => {
                  setEditingEmployee(activeDetailEmployee);
                  setEditJabatan(activeDetailEmployee.jabatan);
                  setEditDivisiId(activeDetailEmployee.divisi_id || '');
                  setEditFoto('');
                }}>
                   Edit
                </button>
                <select
                  className="form-select"
                  style={{ width: '150px', padding: '6px 12px', fontSize: '13px', margin: 0 }}
                  value={selectedMonth}
                  onChange={(e) => setSelectedMonth(e.target.value)}
                >
                  {getMonthOptions().map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* EDIT PEGAWAI MODAL */}
      {editingEmployee && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1001
        }}>
          <div className="panel-card" style={{ width: '95%', maxWidth: '420px', animation: 'slideUp 0.3s', padding: '16px' }}>
            <div className="panel-header" style={{ marginBottom: '12px' }}>
              <span className="panel-title" style={{ fontSize: '16px' }}> Edit: {editingEmployee.nama}</span>
              <button className="btn-sm-action no-print" onClick={() => {
                setEditingEmployee(null);
                setEditJabatan('');
                setEditDivisiId('');
                setEditFoto('');
              }}></button>
            </div>
            
            <div className="panel-body" style={{ padding: '12px' }}>
              <div className="form-group" style={{ marginBottom: '12px' }}>
                <label className="form-label" style={{ fontSize: '13px', marginBottom: '6px' }}> Foto</label>
                {editFoto ? (
                  <div style={{ marginBottom: '8px' }}>
                    <img src={editFoto} alt="Preview" style={{ width: '120px', height: '120px', objectFit: 'cover', borderRadius: '6px', border: '2px solid #10b981' }} />
                    <button 
                      className="btn-sm-action btn-sm-delete"
                      onClick={() => setEditFoto('')}
                      style={{ marginTop: '6px', padding: '4px 8px', fontSize: '12px' }}
                    >
                       Hapus
                    </button>
                  </div>
                ) : null}
                <input 
                  type="file" 
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleFotoChange}
                  disabled={isUploadingFoto}
                  style={{ padding: '6px', borderRadius: '4px', border: '1px solid var(--border)', width: '100%', cursor: 'pointer', fontSize: '12px' }}
                />
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Max 5MB  JPG/PNG</div>
              </div>

              <div className="form-group" style={{ marginBottom: '12px' }}>
                <label className="form-label" style={{ fontSize: '13px', marginBottom: '4px' }}>Jabatan</label>
                <input 
                  type="text"
                  className="form-input"
                  placeholder="Contoh: Developer"
                  value={editJabatan}
                  onChange={(e) => setEditJabatan(e.target.value)}
                  style={{ fontSize: '13px', padding: '6px' }}
                />
              </div>

              <div className="form-group" style={{ marginBottom: '12px' }}>
                <label className="form-label" style={{ fontSize: '13px', marginBottom: '4px' }}>Divisi</label>
                <select 
                  className="form-input"
                  value={editDivisiId}
                  onChange={(e) => setEditDivisiId(e.target.value)}
                  style={{ fontSize: '13px', padding: '6px' }}
                >
                  <option value="">-- Tanpa Divisi --</option>
                  {divisi.map(d => (
                    <option key={d.id} value={d.id}>{d.nama_divisi}</option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '12px' }}>
                <button 
                  className="btn-action btn-action-secondary"
                  onClick={() => {
                    setEditingEmployee(null);
                    setEditJabatan('');
                    setEditDivisiId('');
                    setEditFoto('');
                  }}
                  style={{ padding: '6px 12px', fontSize: '12px' }}
                >
                  Batal
                </button>
                <button 
                  className="btn-action btn-action-primary"
                  onClick={editPegawai}
                  disabled={isUploadingFoto}
                  style={{ padding: '6px 12px', fontSize: '12px' }}
                >
                   Simpan
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL LOGIN CREDENTIALS
          ========================================== */}
      {showLoginModal && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1001
        }} onClick={() => setShowLoginModal(null)}>
          <div className="panel-card" style={{ width: '95%', maxWidth: '420px', animation: 'slideUp 0.3s', padding: '24px' }} onClick={(e) => e.stopPropagation()}>
            <div className="panel-header" style={{ marginBottom: '20px' }}>
              <span className="panel-title" style={{ fontSize: '18px' }}> Data Login & Akses</span>
              <button className="btn-sm-action no-print" onClick={() => setShowLoginModal(null)}></button>
            </div>
            
            <div className="panel-body" style={{ paddingLeft: 0, paddingRight: 0 }}>
              <div style={{ background: '#fef3c7', border: '1px solid #f59e0b', padding: '16px', borderRadius: '8px', marginBottom: '20px' }}>
                <h4 style={{ fontSize: '14px', color: 'var(--text-heading)', marginBottom: '12px', fontWeight: 700 }}>Pegawai: {showLoginModal.nama}</h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <div style={{ fontSize: '12px', color: '#92400e', fontWeight: 600, marginBottom: '6px' }}> Username</div>
                    <div style={{ fontSize: '13px', fontFamily: 'monospace', fontWeight: 600, color: 'var(--text-heading)', background: '#fff', padding: '8px 12px', borderRadius: '6px', border: '1px solid #f59e0b' }}>
                      {showLoginModal.username}
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '12px', color: '#92400e', fontWeight: 600, marginBottom: '6px' }}> Password</div>
                    <div style={{ fontSize: '13px', fontFamily: 'monospace', fontWeight: 600, color: 'var(--text-heading)', background: '#fff', padding: '8px 12px', borderRadius: '6px', border: '1px solid #f59e0b' }}>
                      {showLoginModal.password_raw || showLoginModal.password || ''}
                    </div>
                  </div>
                </div>
                <div style={{ fontSize: '11px', color: '#92400e', marginTop: '12px', fontStyle: 'italic' }}>
                   Jangan bagikan data ini kepada orang yang tidak berwenang. Hanya untuk admin.
                </div>
              </div>
              
              <button 
                className="btn-action btn-action-primary"
                onClick={() => setShowLoginModal(null)}
                style={{ width: '100%', padding: '10px' }}
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL ATTENDANCE DETAILS
          ========================================== */}
      {activeAbsensiEmployee && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1001
        }} onClick={() => setActiveAbsensiEmployee(null)}>
          <div className="panel-card" style={{ width: '95%', maxWidth: '500px', animation: 'slideUp 0.3s', maxHeight: '80vh', overflowY: 'auto' }} onClick={(e) => e.stopPropagation()}>
            <div className="panel-header">
              <span className="panel-title"> Detail Kehadiran Pegawai</span>
              <button className="btn-sm-action no-print" onClick={() => setActiveAbsensiEmployee(null)}></button>
            </div>
            
            <div className="panel-body">
              <div style={{ marginBottom: '20px' }}>
                <h4 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-heading)', marginBottom: '12px' }}>
                   {activeAbsensiEmployee.nama}
                </h4>
                <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '16px' }}>
                  ID: PG-{activeAbsensiEmployee.id}
                </div>
              </div>

              <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '8px', marginBottom: '20px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <div style={{ fontSize: '12px', color: 'var(--text-faint)', fontWeight: 600, marginBottom: '4px' }}> Tanggal</div>
                    <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-heading)' }}>
                      {new Date(activeAbsensiEmployee.tanggal).toLocaleDateString('id-ID', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '12px', color: 'var(--text-faint)', fontWeight: 600, marginBottom: '4px' }}> Status</div>
                    <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-heading)' }}>
                      {activeAbsensiEmployee.status === 'Hadir' && ' Hadir'}
                      {activeAbsensiEmployee.status === 'Izin' && ' Izin'}
                      {activeAbsensiEmployee.status === 'Sakit' && ' Sakit'}
                      {activeAbsensiEmployee.status === 'Alpa' && ' Alpa'}
                    </div>
                  </div>
                </div>
              </div>

              {/* Show all attendance records for this employee */}
              <div style={{ marginBottom: '20px' }}>
                <h4 style={{ fontSize: '14px', fontWeight: 700, color: 'var(--text-heading)', marginBottom: '12px' }}>
                   Semua Kehadiran {activeAbsensiEmployee.nama}
                </h4>
                <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
                  {absensi.filter(a => a.nama === activeAbsensiEmployee.nama).length > 0 ? (
                    <table className="custom-table" style={{ marginBottom: 0 }}>
                      <thead>
                        <tr>
                          <th>Tanggal</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {absensi.filter(a => a.nama === activeAbsensiEmployee.nama).map((record) => {
                          const formattedDate = new Date(record.tanggal).toLocaleDateString('id-ID', {
                            weekday: 'short',
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric'
                          });
                          let badgeClass = 'badge-success';
                          if (record.status === 'Izin') badgeClass = 'badge-warning';
                          else if (record.status === 'Sakit') badgeClass = 'badge-primary';
                          else if (record.status === 'Alpa') badgeClass = 'badge-danger';

                          return (
                            <tr key={record.id}>
                              <td>{formattedDate}</td>
                              <td><span className={`badge ${badgeClass}`}>{record.status}</span></td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  ) : (
                    <div style={{ padding: '20px', textAlign: 'center', color: 'var(--text-faint)' }}>
                      Tidak ada data kehadiran untuk pegawai ini.
                    </div>
                  )}
                </div>
              </div>

              {/* Statistics */}
              <div style={{ background: '#f0f9ff', border: '1px solid #bfdbfe', padding: '16px', borderRadius: '8px', marginBottom: '20px' }}>
                <h4 style={{ fontSize: '13px', fontWeight: 700, color: 'var(--text-heading)', marginBottom: '12px' }}> Statistik Kehadiran</h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ color: 'var(--text-faint)' }}> Hadir:</span>
                    <span style={{ fontWeight: 700, marginLeft: '8px', color: '#059669' }}>
                      {absensi.filter(a => a.nama === activeAbsensiEmployee.nama && a.status === 'Hadir').length}
                    </span>
                  </div>
                  <div>
                    <span style={{ color: 'var(--text-faint)' }}> Izin/Sakit:</span>
                    <span style={{ fontWeight: 700, marginLeft: '8px', color: '#d97706' }}>
                      {absensi.filter(a => a.nama === activeAbsensiEmployee.nama && (a.status === 'Izin' || a.status === 'Sakit')).length}
                    </span>
                  </div>
                  <div>
                    <span style={{ color: 'var(--text-faint)' }}> Alpa:</span>
                    <span style={{ fontWeight: 700, marginLeft: '8px', color: '#dc2626' }}>
                      {absensi.filter(a => a.nama === activeAbsensiEmployee.nama && a.status === 'Alpa').length}
                    </span>
                  </div>
                  <div>
                    <span style={{ color: 'var(--text-faint)' }}> Terlambat:</span>
                    <span style={{ fontWeight: 700, marginLeft: '8px', color: '#dc2626' }}>
                      {absensi.filter(a => a.nama === activeAbsensiEmployee.nama && a.keterangan_jam === 'Terlambat').length}
                    </span>
                  </div>
                  <div>
                    <span style={{ color: 'var(--text-faint)' }}> Lembur:</span>
                    <span style={{ fontWeight: 700, marginLeft: '8px', color: '#7c3aed' }}>
                      {absensi.filter(a => a.nama === activeAbsensiEmployee.nama && a.is_lembur == 1).length}
                    </span>
                  </div>
                </div>
              </div>

              <button 
                className="btn-action btn-action-primary"
                onClick={() => setActiveAbsensiEmployee(null)}
                style={{ width: '100%', padding: '10px' }}
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
      {(activeDetailEmployee || currentEmployee) && (
        <div className="print-only-container">
          <div style={{ textAlign: 'center', borderBottom: '2px solid #1e293b', paddingBottom: '12px', marginBottom: '20px' }}>
            <h1 style={{ fontSize: '20pt', fontWeight: 'bold', margin: '0 0 6px 0', color: 'black' }}>LAPORAN REKAP BULANAN KEHADIRAN KARYAWAN</h1>
            <p style={{ fontSize: '12pt', fontWeight: 'bold', margin: '6px 0 0 0', color: 'var(--text-heading)' }}>
              Periode: {(() => {
                const [year, month] = selectedMonth.split('-');
                const dateObj = new Date(parseInt(year), parseInt(month) - 1, 1);
                return dateObj.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
              })()}
            </p>
            <p style={{ fontSize: '10pt', margin: '4px 0 0 0', color: 'var(--text-muted)' }}>Sistem Presensi Digital - PresensiHub</p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px', fontSize: '11pt', color: 'black' }}>
            <div>
              <strong>Nama Karyawan:</strong> {activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama} <br />
              <strong>Jabatan:</strong> {activeDetailEmployee ? activeDetailEmployee.jabatan : currentEmployee?.jabatan} <br />
              <strong>Divisi:</strong> {activeDetailEmployee ? activeDetailEmployee.nama_divisi : currentEmployee?.nama_divisi || 'Tanpa Divisi'}
            </div>
            <div style={{ textAlign: 'right' }}>
              <strong>Tanggal Cetak:</strong> {new Date().toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })} <br />
              <strong>Status Dokumen:</strong> Cetak Resmi Sistem
            </div>
          </div>

          <h3 style={{ borderBottom: '1px solid #cbd5e1', paddingBottom: '6px', marginBottom: '10px', fontSize: '12pt', color: 'black' }}>Rekapitulasi Kehadiran</h3>
          <table style={{ width: '100%', marginBottom: '20px', borderCollapse: 'collapse', textAlign: 'center' }}>
            <thead>
              <tr style={{ background: '#f1f5f9' }}>
                <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Hadir </th>
                <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Izin </th>
                <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Sakit </th>
                <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Alpa </th>
                <th style={{ border: '1px solid #cbd5e1', padding: '8px', color: 'black', fontSize: '10pt' }}>Total Hari</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                  {(() => {
                    const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                    return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Hadir').length;
                  })()} Hari
                </td>
                <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                  {(() => {
                    const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                    return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Izin').length;
                  })()} Hari
                </td>
                <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                  {(() => {
                    const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                    return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Sakit').length;
                  })()} Hari
                </td>
                <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                  {(() => {
                    const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                    return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth) && a.status === 'Alpa').length;
                  })()} Hari
                </td>
                <td style={{ border: '1px solid #cbd5e1', padding: '8px', fontWeight: 'bold', color: 'black' }}>
                  {(() => {
                    const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                    return absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth)).length;
                  })()} Hari
                </td>
              </tr>
            </tbody>
          </table>

          <h3 style={{ borderBottom: '1px solid #cbd5e1', paddingBottom: '6px', marginBottom: '10px', fontSize: '12pt', color: 'black' }}>Rincian Tanggal Kehadiran</h3>
          <table className="print-table">
            <thead>
              <tr>
                <th>No</th>
                <th>Hari & Tanggal</th>
                <th>Jam Masuk</th>
                <th>Jam Keluar</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {(() => {
                const name = activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama;
                const list = absensi.filter((a) => a.nama.toLowerCase() === name?.toLowerCase() && a.tanggal.startsWith(selectedMonth));
                if (list.length === 0) {
                  return (
                    <tr>
                      <td colSpan="5" style={{ textAlign: 'center', color: 'black' }}>Tidak ada riwayat kehadiran</td>
                    </tr>
                  );
                }
                return list.map((a, idx) => {
                  const fDate = new Date(a.tanggal).toLocaleDateString('id-ID', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  });
                  return (
                    <tr key={a.id}>
                      <td style={{ color: 'black' }}>{idx + 1}</td>
                      <td style={{ color: 'black' }}>{fDate}</td>
                      <td style={{ color: 'black' }}>{a.status === 'Hadir' ? (a.jam_masuk ? `${a.jam_masuk.slice(0, 5)} WIB` : '-') : '-'}</td>
                      <td style={{ color: 'black' }}>{a.status === 'Hadir' ? (a.jam_keluar ? `${a.jam_keluar.slice(0, 5)} WIB` : 'Belum Scan Pulang ') : '-'}</td>
                      <td style={{ color: 'black' }}>{a.status}</td>
                    </tr>
                  );
                });
              })()}
            </tbody>
          </table>

          <div style={{ marginTop: '50px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', fontSize: '11pt', color: 'black' }}>
            <div style={{ textAlign: 'center' }}>
              <p>Mengetahui,</p>
              <br /><br /><br />
              <p style={{ textDecoration: 'underline', fontWeight: 'bold' }}>Manager HRD</p>
            </div>
            <div style={{ textAlign: 'center' }}>
              <p>Penerima Laporan,</p>
              <br /><br /><br />
              <p style={{ textDecoration: 'underline', fontWeight: 'bold' }}>{activeDetailEmployee ? activeDetailEmployee.nama : currentEmployee?.nama}</p>
            </div>
          </div>
        </div>
      )}

      {/* ===== CUSTOM ALERT MODAL (pengganti alert() bawaan browser) ===== */}
      {customAlert.show && (
        <div style={{
          position: 'fixed', inset: 0,
          background: 'rgba(15,23,42,0.65)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 9999, padding: '20px'
        }}>
          <div style={{
            background: 'var(--bg-card)', borderRadius: '20px',
            padding: '32px', width: '100%', maxWidth: '440px',
            boxShadow: '0 25px 50px -12px rgba(0,0,0,0.35)',
            border: '1px solid var(--border)',
            animation: 'scaleUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            {/* Header Kelompok 2 */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: '10px',
              marginBottom: '18px', paddingBottom: '14px',
              borderBottom: '1px solid var(--border)'
            }}>
              <div style={{
                width: '36px', height: '36px', borderRadius: '10px',
                background: 'var(--primary)', display: 'flex',
                alignItems: 'center', justifyContent: 'center',
                fontSize: '18px', flexShrink: 0
              }}>💡</div>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Kelompok 2</div>
                <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-heading)' }}>{customAlert.title}</div>
              </div>
            </div>
            {/* Pesan */}
            <div style={{
              fontSize: '14px', color: 'var(--text-main)', lineHeight: '1.7',
              whiteSpace: 'pre-line', marginBottom: '24px',
              background: 'var(--bg-subtle)', borderRadius: '12px', padding: '14px 16px'
            }}>
              {customAlert.message}
            </div>
            <button
              onClick={() => setCustomAlert({ show: false, title: '', message: '' })}
              style={{
                width: '100%', padding: '11px',
                background: 'var(--primary)', color: '#fff',
                border: 'none', borderRadius: '10px',
                fontWeight: 700, fontSize: '14px', cursor: 'pointer',
                transition: 'opacity 0.2s'
              }}
              onMouseOver={e => e.target.style.opacity = '0.88'}
              onMouseOut={e => e.target.style.opacity = '1'}
            >
              OK
            </button>
          </div>
        </div>
      )}

      {/* ===== CUSTOM CONFIRM MODAL (pengganti window.confirm() bawaan browser) ===== */}
      {customConfirm.show && (
        <div style={{
          position: 'fixed', inset: 0,
          background: 'rgba(15,23,42,0.65)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 9999, padding: '20px'
        }}>
          <div style={{
            background: 'var(--bg-card)', borderRadius: '20px',
            padding: '32px', width: '100%', maxWidth: '440px',
            boxShadow: '0 25px 50px -12px rgba(0,0,0,0.35)',
            border: '1px solid var(--border)',
            animation: 'scaleUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            {/* Header Kelompok 2 */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: '10px',
              marginBottom: '18px', paddingBottom: '14px',
              borderBottom: '1px solid var(--border)'
            }}>
              <div style={{
                width: '36px', height: '36px', borderRadius: '10px',
                background: 'rgba(239,68,68,0.12)', display: 'flex',
                alignItems: 'center', justifyContent: 'center',
                fontSize: '18px', flexShrink: 0
              }}>⚠️</div>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-faint)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Kelompok 2</div>
                <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-heading)' }}>{customConfirm.title}</div>
              </div>
            </div>
            {/* Pesan */}
            <div style={{
              fontSize: '14px', color: 'var(--text-main)', lineHeight: '1.7',
              whiteSpace: 'pre-line', marginBottom: '24px',
              background: 'var(--bg-subtle)', borderRadius: '12px', padding: '14px 16px'
            }}>
              {customConfirm.message}
            </div>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                onClick={() => {
                  setCustomConfirm({ show: false, title: '', message: '', onConfirm: null });
                }}
                style={{
                  flex: 1, padding: '11px',
                  background: 'var(--bg-subtle)', color: 'var(--text-main)',
                  border: '1px solid var(--border)', borderRadius: '10px',
                  fontWeight: 600, fontSize: '14px', cursor: 'pointer'
                }}
              >
                Batal
              </button>
              <button
                onClick={() => {
                  const fn = customConfirm.onConfirm;
                  setCustomConfirm({ show: false, title: '', message: '', onConfirm: null });
                  if (fn) fn();
                }}
                style={{
                  flex: 1, padding: '11px',
                  background: 'var(--danger)', color: '#fff',
                  border: 'none', borderRadius: '10px',
                  fontWeight: 700, fontSize: '14px', cursor: 'pointer'
                }}
              >
                Ya, Lanjutkan
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast.show && (
        <div className={`custom-toast ${toast.type === 'error' ? 'toast-error' : 'toast-success'}`}>
          <span>{toast.type === 'error' ? '' : ''}</span>
          <span>{toast.message}</span>
        </div>
      )}


      {/* ==========================================
          MODAL PREVIEW FOTO BUKTI
          ========================================== */}
      {previewImage && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.8)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '20px'
        }} onClick={() => { setPreviewImage(null); setPreviewAlasan(null); }}>
          <div style={{
            position: 'relative',
            background: 'white',
            borderRadius: '24px',
            padding: '32px',
            width: '100%',
            maxWidth: '500px',
            maxHeight: '90vh',
            display: 'flex',
            flexDirection: 'column',
            boxShadow: 'var(--shadow-premium)',
            animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)',
            overflowY: 'auto'
          }} onClick={(e) => e.stopPropagation()}>
            <button
              style={{
                position: 'absolute',
                top: '16px',
                right: '16px',
                background: '#f1f5f9',
                color: 'var(--text-muted)',
                border: 'none',
                borderRadius: '50%',
                width: '36px',
                height: '36px',
                cursor: 'pointer',
                fontWeight: 'bold',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '18px',
                transition: 'all 0.2s'
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = '#ef4444'; e.currentTarget.style.color = 'white'; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = '#f1f5f9'; e.currentTarget.style.color = '#64748b'; }}
              onClick={() => { setPreviewImage(null); setPreviewAlasan(null); }}
            >
              
            </button>

            <h3 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '20px', borderBottom: '1px solid #cbd5e1', paddingBottom: '10px', textAlign: 'left' }}>
               Detail Pengajuan
            </h3>

            {/* Alasan / Keterangan Section */}
            {previewAlasan && (
              <div style={{ marginBottom: '20px', textAlign: 'left' }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, color: 'var(--text-main)', marginBottom: '6px' }}>
                  Keterangan / Alasan:
                </label>
                <div style={{
                  background: '#f8fafc',
                  border: '1px solid var(--border)',
                  borderRadius: '12px',
                  padding: '16px',
                  fontSize: '14px',
                  color: '#334155',
                  lineHeight: '1.6',
                  whiteSpace: 'pre-wrap'
                }}>
                  {previewAlasan}
                </div>
              </div>
            )}

            {/* Foto Bukti Section */}
            {previewImage && previewImage !== 'NO_IMAGE' && (
              <div style={{ textAlign: 'center' }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, color: 'var(--text-main)', marginBottom: '8px', textAlign: 'left' }}>
                  Foto Bukti:
                </label>
                <img
                  src={previewImage}
                  alt="Bukti Foto"
                  style={{
                    maxWidth: '100%',
                    maxHeight: '45vh',
                    borderRadius: '16px',
                    objectFit: 'contain',
                    border: '1px solid var(--border)',
                    boxShadow: 'var(--shadow-sm)'
                  }}
                />
              </div>
            )}
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL WARNING CUTI BIASA EXCEEDED
          ========================================== */}
      {biasaWarning.show && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '20px'
        }}>
          <div style={{
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
            border: '1px solid rgba(239, 68, 68, 0.2)',
            borderRadius: '24px',
            padding: '32px',
            width: '100%',
            maxWidth: '460px',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            textAlign: 'center',
            animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            <div style={{
              width: '80px',
              height: '80px',
              background: 'rgba(239, 68, 68, 0.1)',
              color: 'var(--danger)',
              fontSize: '36px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '50%',
              margin: '0 auto 20px auto',
              animation: 'pulse 2s infinite'
            }}>
              
            </div>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '12px' }}>
              Jatah Cuti Biasa Habis!
            </h2>
            <p style={{ fontSize: '14px', color: 'var(--text-muted)', lineHeight: '1.6', marginBottom: '24px' }}>
              {biasaWarning.message}
            </p>
            <button 
              className="btn-action btn-action-primary" 
              style={{ width: '100%', padding: '12px' }}
              onClick={() => setBiasaWarning({ show: false, message: '' })}
            >
              Mengerti
            </button>
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL WARNING CUTI TAMBAHAN EXCEEDED
          ========================================== */}
      {tambahanWarning.show && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '20px'
        }}>
          <div style={{
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
            border: '1px solid rgba(239, 68, 68, 0.2)',
            borderRadius: '24px',
            padding: '32px',
            width: '100%',
            maxWidth: '460px',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            textAlign: 'center',
            animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            <div style={{
              width: '80px',
              height: '80px',
              background: 'rgba(239, 68, 68, 0.1)',
              color: 'var(--danger)',
              fontSize: '36px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '50%',
              margin: '0 auto 20px auto',
              animation: 'pulse 2s infinite'
            }}>
              
            </div>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '12px' }}>
              Batasan Hari Terlewati!
            </h2>
            <p style={{ fontSize: '14px', color: 'var(--text-muted)', lineHeight: '1.6', marginBottom: '24px' }}>
              {tambahanWarning.message}
            </p>
            <button 
              className="btn-action btn-action-primary" 
              style={{ width: '100%', padding: '12px' }}
              onClick={() => setTambahanWarning({ show: false, message: '' })}
            >
              Mengerti
            </button>
          </div>
        </div>
      )}
      {/* MODAL: ADMIN APPROVAL CONFIRMATION (IZIN/SAKIT & CUTI TAMBAHAN) */}
      {approvalModal && (
        <div style={{
          position: 'fixed', inset: 0,
          background: 'rgba(15, 23, 42, 0.75)',
          backdropFilter: 'blur(10px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 1200, padding: '20px'
        }}>
          <div style={{
            background: 'white',
            borderRadius: '16px', padding: '20px',
            width: '100%', maxWidth: '400px',
            maxHeight: '90vh', overflowY: 'auto',
            boxShadow: '0 30px 60px -10px rgba(0,0,0,0.3)',
            animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{
                width: '44px', height: '44px', borderRadius: '10px', flexShrink: 0,
                background: approvalModal.type === 'izin' ? 'rgba(245,158,11,0.12)' : 'rgba(16,185,129,0.12)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '22px'
              }}>
                {approvalModal.type === 'izin' ? (approvalModal.data.status === 'Pending Izin' ? '🏠' : '🏥') : '🌴'}
              </div>
              <div>
                <h2 style={{ fontSize: '17px', fontWeight: 800, color: '#0f172a', marginBottom: '2px' }}>
                  {approvalModal.type === 'izin'
                    ? `Pengajuan ${approvalModal.data.status === 'Pending Izin' ? 'Izin' : 'Sakit'}`
                    : `Pengajuan Cuti Tambahan`}
                </h2>
                <p style={{ fontSize: '11px', color: '#64748b' }}>Periksa detail sebelum memberi keputusan</p>
              </div>
            </div>

            {/* Details Card */}
            <div style={{
              background: '#f8fafc',
              borderRadius: '12px',
              padding: '14px',
              marginBottom: '14px',
              display: 'flex', flexDirection: 'column', gap: '10px'
            }}>
              {/* Karyawan */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>Karyawan</span>
                <span style={{ fontSize: '13px', fontWeight: 800, color: '#0f172a' }}>
                  {approvalModal.data.nama}
                  {approvalModal.type === 'cuti' && approvalModal.data.nama_divisi && (
                    <span style={{ fontSize: '10px', color: '#6366f1', fontWeight: 600, marginLeft: '6px' }}>
                      ({approvalModal.data.nama_divisi})
                    </span>
                  )}
                </span>
              </div>
              {/* Jenis */}
              {approvalModal.type === 'cuti' && (
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>Keperluan</span>
                  <span style={{ fontSize: '13px', fontWeight: 700, color: '#10b981' }}>{approvalModal.data.keperluan || 'Cuti Tambahan'}</span>
                </div>
              )}
              {/* Durasi - PROMINENT DISPLAY */}
              <div style={{ 
                background: 'linear-gradient(135deg, rgba(99,102,241,0.12), rgba(99,102,241,0.03))',
                borderRadius: '10px', padding: '10px', marginBottom: '6px',
                border: '1px solid rgba(99,102,241,0.3)',
                textAlign: 'center'
              }}>
                <div style={{ fontSize: '11px', color: '#64748b', fontWeight: 600, marginBottom: '4px' }}>DURASI CUTI</div>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: '4px' }}>
                  <span style={{ fontSize: '28px', fontWeight: 900, color: '#6366f1' }}>
                    {approvalModal.type === 'izin' ? approvalModal.data.durasi : approvalModal.data.durasi_hari}
                  </span>
                  <span style={{ fontSize: '13px', fontWeight: 700, color: '#64748b' }}>Hari Kerja</span>
                </div>
                <div style={{ fontSize: '10px', color: '#6366f1', fontWeight: 600, marginTop: '4px' }}>
                  {(() => {
                    const d = approvalModal.type === 'izin';
                    const start = d ? approvalModal.data.firstDate : approvalModal.data.tanggal_mulai;
                    const end = d ? approvalModal.data.lastDate : approvalModal.data.tanggal_selesai;
                    if (!start) return '-';
                    const fStart = new Date(start).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
                    const fEnd = end ? new Date(end).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : fStart;
                    return start === end ? fStart : `${fStart} – ${fEnd}`;
                  })()}
                </div>
              </div>
              {/* Alasan */}
              {approvalModal.data.alasan && (
                <div>
                  <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, display: 'block', marginBottom: '4px' }}>Alasan / Keterangan</span>
                  <div style={{
                    background: 'white', borderRadius: '8px', padding: '8px 10px',
                    fontSize: '12px', color: '#334155', fontStyle: 'italic',
                    border: '1px solid #e2e8f0', lineHeight: '1.4'
                  }}>
                    {approvalModal.data.alasan}
                  </div>
                </div>
              )}
              {/* Foto Bukti */}
              {approvalModal.data.foto_bukti && (
                <div>
                  <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, display: 'block', marginBottom: '4px' }}>Foto Bukti</span>
                  <img
                     src={approvalModal.data.foto_bukti}
                     alt="Bukti"
                     style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover', cursor: 'pointer', border: '1px solid #e2e8f0' }}
                     onClick={() => { setPreviewImage(approvalModal.data.foto_bukti); setPreviewAlasan(approvalModal.data.alasan || ''); }}
                  />
                </div>
              )}
            </div>

            {/* Info note for approved period */}
            <div style={{
              background: 'rgba(99,102,241,0.07)', borderRadius: '8px', padding: '8px 12px',
              fontSize: '11px', color: '#6366f1', fontWeight: 600, marginBottom: '14px', lineHeight: '1.4'
            }}>
              ✅ Setelah ACC, seluruh periode {approvalModal.type === 'izin' ? 'izin/sakit' : 'cuti'} tersebut akan otomatis tercatat — tanpa perlu approve ulang setiap hari.
            </div>

            {/* Buttons */}
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                className="btn-action btn-action-primary"
                style={{ flex: 1, padding: '10px', background: 'linear-gradient(135deg, #10b981, #059669)', fontSize: '13px', fontWeight: 800 }}
                onClick={() => {
                  if (approvalModal.type === 'izin') {
                    approveRejectAbsensi(approvalModal.data.pegawai_id, approvalModal.data.alasan, approvalModal.data.status, 'approve');
                  } else {
                    approveRejectCuti(approvalModal.data.id, 'approve');
                  }
                }}
              >
                ✅ Setujui (ACC)
              </button>
              <button
                className="btn-action btn-action-primary"
                style={{ flex: 1, padding: '10px', background: 'linear-gradient(135deg, #ef4444, #dc2626)', fontSize: '13px', fontWeight: 800 }}
                onClick={() => {
                  if (approvalModal.type === 'izin') {
                    approveRejectAbsensi(approvalModal.data.pegawai_id, approvalModal.data.alasan, approvalModal.data.status, 'reject');
                  } else {
                    approveRejectCuti(approvalModal.data.id, 'reject');
                  }
                }}
              >
                ❌ Tolak
              </button>
              <button
                className="btn-action btn-action-secondary"
                style={{ padding: '10px 14px', fontSize: '13px' }}
                onClick={() => setApprovalModal(null)}
              >
                Batal
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ==========================================
          MODAL GANTI PASSWORD (EMPLOYEE)
          ========================================== */}

      {isChangePasswordOpen && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '20px'
        }}>
          <div style={{
            background: 'white',
            borderRadius: '24px',
            padding: '32px',
            width: '100%',
            maxWidth: '420px',
            boxShadow: 'var(--shadow-premium)',
            animation: 'scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)'
          }}>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-heading)', marginBottom: '8px', textAlign: 'center' }}>
               Ganti Password Anda
            </h2>
            <p style={{ fontSize: '13px', color: 'var(--text-muted)', textAlign: 'center', marginBottom: '24px' }}>
              Masukkan password lama dan password baru Anda di bawah ini.
            </p>

            <div className="dashboard-form">
              <div>
                <label htmlFor="old-pass">Password Lama (Opsional)</label>
                <div className="input-container">
                  <input
                    id="old-pass"
                    type={showEmpOldPass ? 'text' : 'password'}
                    className="form-input-plain"
                    placeholder="Password Lama Anda"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    style={{ paddingRight: '42px' }}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowEmpOldPass(!showEmpOldPass)}
                    title={showEmpOldPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showEmpOldPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
              </div>

              <div>
                <label htmlFor="new-pass">Password Baru</label>
                <div className="input-container">
                  <input
                    id="new-pass"
                    type={showEmpNewPass ? 'text' : 'password'}
                    className="form-input-plain"
                    placeholder="Password Baru Anda"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    style={{ paddingRight: '42px' }}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowEmpNewPass(!showEmpNewPass)}
                    title={showEmpNewPass ? 'Sembunyikan password' : 'Tampilkan password'}
                  >
                    {showEmpNewPass ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ pointerEvents: 'none' }}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '12px' }}>
                <button
                  type="button"
                  className="btn-action btn-action-secondary"
                  style={{ flex: 1 }}
                  onClick={() => {
                    setIsChangePasswordOpen(false);
                    setOldPassword('');
                    setNewPassword('');
                  }}
                >
                  Batal
                </button>
                <button
                  type="button"
                  className="btn-action btn-action-primary"
                  style={{ flex: 1 }}
                  onClick={ubahPassword}
                >
                  Perbarui 
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
