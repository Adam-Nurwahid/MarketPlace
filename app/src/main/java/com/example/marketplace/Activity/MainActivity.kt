package com.example.marketplace.Activity

import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModel
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.CompositePageTransformer
import androidx.viewpager2.widget.MarginPageTransformer
import com.example.marketplace.Model.SliderModel
import com.example.marketplace.R
import com.example.marketplace.SliderAdapter
import com.example.marketplace.ViewModel.MainViewModel

class MainActivity : AppCompatActivity() {
    private val ViewModel=MainViewModel()
    private lateinit var binding:ActivityMainBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding= ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        initBanner()
    }

    private fun initBanner() {
        binding.progressBarBanner.visibility= View.VISIBLE
            viewModel.Banners.observe( this, Observer { item ->


            })
    }

    private fun banners(images:List<SliderModel>){
        binding.viewpagerSlider.adapter=SliderAdapter(images, binding.viewpagerSlider)
        binding.viewpagerSlider.clipToPadding=false
        binding.viewpagerSlider.clipChildren=false
        binding.viewpagerSlider.offscreenPagelimit=3
        binding.viewpagerSlider.getChildAt(0).overScroolMode=RecyclerView.OVER_SCROLL_NEVER

        val compositePageTransformer=CompositePageTransformer().apply {
            addTransformer(MarginPageTransformer(40))
        }
        binding.viewpagerSlider.setPageTransformer(compositePageTransformer)
        if(image.size>1)
            binding.
}