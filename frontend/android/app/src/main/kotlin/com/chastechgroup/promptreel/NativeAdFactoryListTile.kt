package com.chastechgroup.promptreel

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

/**
 * Factory that renders a native ad as a compact list-tile style card.
 * The layout is defined programmatically here — no XML needed.
 */
class NativeAdFactoryListTile(private val layoutInflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        // Build the NativeAdView programmatically
        val nativeAdView = NativeAdView(layoutInflater.context)
        nativeAdView.layoutParams = android.view.ViewGroup.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.WRAP_CONTENT
        )

        // Create inner layout
        val container = android.widget.LinearLayout(layoutInflater.context).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            setPadding(24, 16, 24, 16)
            layoutParams = android.view.ViewGroup.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // Icon
        val iconView = ImageView(layoutInflater.context).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(80, 80).also {
                it.marginEnd = 24
            }
            scaleType = ImageView.ScaleType.CENTER_CROP
        }
        nativeAd.icon?.drawable?.let { iconView.setImageDrawable(it) }
        nativeAdView.iconView = iconView
        container.addView(iconView)

        // Text column
        val textCol = android.widget.LinearLayout(layoutInflater.context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            layoutParams = android.widget.LinearLayout.LayoutParams(0, android.view.ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }

        val headlineView = TextView(layoutInflater.context).apply {
            textSize = 14f
            setTextColor(android.graphics.Color.parseColor("#F0F0FF"))
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            text = nativeAd.headline ?: ""
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        nativeAdView.headlineView = headlineView
        textCol.addView(headlineView)

        val bodyView = TextView(layoutInflater.context).apply {
            textSize = 12f
            setTextColor(android.graphics.Color.parseColor("#AAAAAE"))
            text = nativeAd.body ?: ""
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        nativeAdView.bodyView = bodyView
        textCol.addView(bodyView)
        container.addView(textCol)

        // CTA button
        val ctaView = TextView(layoutInflater.context).apply {
            text = nativeAd.callToAction ?: "Learn More"
            textSize = 11f
            setTextColor(android.graphics.Color.parseColor("#000000"))
            setBackgroundColor(android.graphics.Color.parseColor("#FFB830"))
            setPadding(20, 10, 20, 10)
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT
            ).also { it.gravity = android.view.Gravity.CENTER_VERTICAL }
        }
        nativeAdView.callToActionView = ctaView
        container.addView(ctaView)

        nativeAdView.addView(container)
        nativeAdView.setNativeAd(nativeAd)
        return nativeAdView
    }
}
