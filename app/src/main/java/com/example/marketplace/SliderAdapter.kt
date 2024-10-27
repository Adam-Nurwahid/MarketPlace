package com.example.marketplace

import android.transition.Slide
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import com.example.marketplace.Model.SliderModel
import com.google.firebase.database.core.Context

class SliderAdapter(private var sliderItems:List<SliderModel>,
                    private val viewPager2:ViewPager2
):RecyclerView.Adapter<SliderAdapter.SliderViewHolder> {

    private lateinit var context: Context
    private val runnable: Runnable{
        sliderItems:sliderItems
        notifyDataSetChanged()
    }


    override fun onCreateViewHolder(
        parent: ViewGroup,
        viewType: Int
    ): SliderAdapter.SliderViewHolder {
        context = parent.context
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.slider_item_container, parent, false)
        return SliderViewHolder(view)
    }

    override fun onBindViewHolder(holder: SliderAdapter.SliderViewHolder, position: Int) {
        holder.setImage(SliderItems[position], context)
        if (position == SliderItems.lastIndex - 1) {
            viewPager2.post(runnable)
        }
    }

    override fun getItemCount(): Int = sliderItems.size


    class SliderViewHolder(itemView: View):RecyclerView.ViewHolder(itemView){
        private val imageViews: ImageView = itemView.findViewById(R.id.imageSlider)

        fun setImage(sliderItems: SliderModel, context: Context){

            Glide.with(context)
                .load(sliderItems.url)
                .apply(requestOptions)
                .intro(imageView)
        }

    }
}