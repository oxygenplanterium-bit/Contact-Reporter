package com.oxygenplanterium.contactreporter;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.File;

/* Opens WhatsApp directly on one person's chat with a file attached. */
@CapacitorPlugin(name = "WhatsAppShare")
public class WhatsAppSharePlugin extends Plugin {
    @PluginMethod
    public void send(PluginCall call) {
        String path = call.getString("path");
        String jid = call.getString("jid");
        String mime = call.getString("mime", "application/pdf");
        if (path == null || jid == null || jid.length() < 8) { call.reject("missing"); return; }
        try {
            File f = new File(Uri.parse(path).getPath());
            Uri uri = FileProvider.getUriForFile(getContext(), getContext().getPackageName() + ".fileprovider", f);
            String[] pkgs = new String[] { "com.whatsapp", "com.whatsapp.w4b" };
            for (String pkg : pkgs) {
                Intent i = new Intent(Intent.ACTION_SEND);
                i.setType(mime);
                i.putExtra(Intent.EXTRA_STREAM, uri);
                i.putExtra("jid", jid + "@s.whatsapp.net");
                i.setPackage(pkg);
                i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
                try { getContext().startActivity(i); call.resolve(); return; } catch (ActivityNotFoundException e) { }
            }
            call.reject("whatsapp");
        } catch (Exception e) { call.reject(String.valueOf(e.getMessage())); }
    }
}
