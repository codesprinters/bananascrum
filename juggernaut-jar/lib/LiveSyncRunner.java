package livesync;

import org.jruby.Ruby;
import org.jruby.RubyRuntimeAdapter;
import org.jruby.javasupport.JavaEmbedUtils;  
import java.util.ArrayList;

public class LiveSyncRunner {
    public static void main(String[] args) {
        String[] jrubyArgs = new String[3 + args.length]; 
        jrubyArgs[0] = "-e";
        jrubyArgs[1] = "require 'livesync/livesync_wrapper'";
        jrubyArgs[2] = "livesync";
        for (int i = 0; i < args.length; ++i) {
            jrubyArgs[i + 3] = args[i];
        }
        org.jruby.Main.main(jrubyArgs);
    }
}

