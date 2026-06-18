<?php

namespace App\Http\Controllers;

use App\Models\Feedback;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class FeedbackController extends Controller
{
    use ApiResponseTrait;
    public function store(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeApi($request);
        }

        return $this->disabledWebResponse('Endpoint feedback hanya tersedia melalui API. Gunakan POST /api/feedback.');
    }

    public function indexSuperAdmin(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexSuperAdminApi();
        }

        return $this->disabledWebResponse('Endpoint daftar feedback hanya tersedia melalui API. Gunakan GET /api/super-admin/feedbacks.');
    }

    public function markAsRead(Feedback $feedback)
    {
        return $this->disabledWebResponse('Endpoint tandai feedback hanya tersedia melalui API. Gunakan POST /api/super-admin/feedbacks/{id}/read.');
    }

    public function destroy(Feedback $feedback)
    {
        return $this->disabledWebResponse('Endpoint hapus feedback hanya tersedia melalui API. Gunakan DELETE /api/super-admin/feedbacks/{id}.');
    }

    public function storeApi(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        $feedback = Feedback::create([
            'user_id' => $request->user()->id,
            'message' => $validated['message'],
            'status' => 'unread',
        ]);

        return $this->successResponse($feedback, 'Ulasan/Feedback berhasil dikirim! Terima kasih.', 201);
    }

    public function indexSuperAdminApi()
    {
        $feedbacks = Feedback::with('user')->latest()->get();
        return $this->successResponse($feedbacks, 'Daftar ulasan berhasil diambil.');
    }

    public function markAsReadApi(Feedback $feedback)
    {
        $feedback->update(['status' => 'read']);
        return $this->successResponse($feedback, 'Ulasan ditandai sudah dibaca.');
    }

    public function destroyApi(Feedback $feedback)
    {
        $feedback->delete();
        return $this->successResponse(null, 'Ulasan berhasil dihapus.');
    }
}
