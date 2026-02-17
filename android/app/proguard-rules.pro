# Keep audio service classes
-keep class com.ryanheise.audioservice.** { *; }
-keep interface com.ryanheise.audioservice.** { *; }

# Keep just_audio classes
-keep class com.ryanheise.just_audio.** { *; }
-keep interface com.ryanheise.just_audio.** { *; }

# Keep audio_session classes
-keep class com.ryanheise.audio_session.** { *; }

# Keep audioplayers classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep ExoPlayer classes (used by just_audio)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep MediaSession classes
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# Keep service implementations
-keepclassmembers class * extends android.app.Service {
    public <init>(...);
}

# Keep media browser service
-keep public class * extends androidx.media.MediaBrowserServiceCompat {
    public <init>(...);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
