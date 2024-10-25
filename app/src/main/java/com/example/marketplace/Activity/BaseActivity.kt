package com.example.marketplace.Activity

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

open class BaseActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)


        window.setFlags(
            windowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            windowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
    }
}