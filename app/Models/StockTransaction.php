<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class StockTransaction extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'type', 'amount', 'notes', 'reference', 'balance_after', 'date'];

    protected $casts = [
        'date' => 'datetime',
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function getCurrentBalance($userId = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        $latest = $query->latest('date')->first();
        return $latest?->balance_after ?? 0;
    }

    public static function addTransaction($type, $amount, $notes = null, $reference = null, $userId = null)
    {
        $userId = $userId ?? auth()->id();
        $balance = self::getCurrentBalance($userId);
        
        if ($type === 'in') {
            $balance += $amount;
        } else {
            $balance -= $amount;
        }

        return self::create([
            'user_id' => $userId,
            'type' => $type,
            'amount' => $amount,
            'notes' => $notes,
            'reference' => $reference,
            'balance_after' => $balance,
            'date' => now(),
        ]);
    }

    public static function rebuildBalances($userId = null)
    {
        $query = self::orderBy('date')->orderBy('id');
        if ($userId) {
            $query->where('user_id', $userId);
        }
        $transactions = $query->get();

        $balance = 0;
        foreach ($transactions as $transaction) {
            if ($transaction->type === 'in') {
                $balance += $transaction->amount;
            } else {
                $balance -= $transaction->amount;
            }
            $transaction->update(['balance_after' => $balance]);
        }
    }
}
