<?php

namespace App\Http\Controllers;

use App\Models\Notification as AppNotification;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponseTrait;

    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;

        $notifications = AppNotification::where('user_id', $userId)
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'title' => $notification->title,
                    'message' => $notification->message,
                    'is_read' => (bool)$notification->is_read,
                    'created_at' => $notification->created_at?->toIso8601String(),
                ];
            });

        return $this->successResponse([
            'items' => $notifications,
            'unread_count' => $notifications->where('is_read', false)->count(),
        ], 'Notifikasi berhasil diambil.');
    }

    public function markAsReadApi(Request $request)
    {
        $validated = $request->validate([
            'notification_id' => 'nullable|integer',
        ]);

        $userId = $request->user()->id;

        if (isset($validated['notification_id'])) {
            $notification = AppNotification::where('id', $validated['notification_id'])
                ->where('user_id', $userId)
                ->first();

            if (!$notification) {
                return $this->notFoundResponse('Notifikasi tidak ditemukan.');
            }

            $notification->markAsRead();
        } else {
            AppNotification::where('user_id', $userId)
                ->where('is_read', false)
                ->update(['is_read' => true]);
        }

        return $this->successResponse(null, 'Notifikasi berhasil ditandai dibaca.');
    }
}
