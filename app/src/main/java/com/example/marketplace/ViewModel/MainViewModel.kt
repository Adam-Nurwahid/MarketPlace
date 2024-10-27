package com.example.marketplace.ViewModel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.example.marketplace.Model.SliderModel
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

class MainViewModel(): ViewModel() {

    private val firebaseDatabase=FirebaseDatabase.getInstance()

    private val _banner= MutableLiveData<List<SliderModel>>()

     val banners: LiveData<List<SliderModel>> = _banner

    fun loadbanners(){
        val Ref=firebaseDatabase.getReference("Banner")
        Ref.addValueEventListener(object : ValueEventListener{
            override fun onDataChange(snapshot: DataSnapshot) {
                val lists = mutableListOf<SliderModel>()
                for (ChildSnapshot in snapshot.children) {
                    val list = childsnapshot.getValue(SliderModel::class.java)
                    if (list != null){
                        lists.add(list)
                    }
                }
                    _banner.value = lists
            }

            override fun onCancelled(error: DatabaseError) {
            }

        })
    }

}