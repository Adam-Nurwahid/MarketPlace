package com.example.marketplace.Activity

import android.content.Intent
import android.os.Bundle

class IntroActivity : BaseActivity() {
    private lateinit var binding: ActivityIntroBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityIntroBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.start8tn.setOnClikListener {
            startActivity(Intent( this@IntroActivity.MainActivity::class.java ))
        }
    }
}