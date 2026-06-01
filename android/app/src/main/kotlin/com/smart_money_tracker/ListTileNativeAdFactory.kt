package com.smart_money_tracker

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.my_native_ad, null) as NativeAdView

        // Map headline
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // Map advertiser
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val advertiser = nativeAd.advertiser
        if (advertiser != null) {
            advertiserView.text = advertiser
            advertiserView.visibility = View.VISIBLE
            adView.advertiserView = advertiserView
        } else {
            advertiserView.visibility = View.GONE
        }

        // Map body
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        bodyView.text = nativeAd.body
        adView.bodyView = bodyView

        // Map icon
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
        val icon = nativeAd.icon
        if (icon != null) {
            iconView.setImageDrawable(icon.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        adView.iconView = iconView

        // Map media view
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.mediaView = mediaView

        // Map call to action button
        val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val callToAction = nativeAd.callToAction
        if (callToAction != null) {
            callToActionView.text = callToAction
            callToActionView.visibility = View.VISIBLE
            adView.callToActionView = callToActionView
        } else {
            callToActionView.visibility = View.INVISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
