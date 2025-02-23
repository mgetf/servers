;; Load libs
(require '[babashka.fs :as fs] 
         '[babashka.process :refer [shell process]])

(defn s
  [& args]
  (apply shell {:out :string 
                :err :string
                :dir "/root"} args))


(s "ls")
(fs/delete (first (fs/glob "." "*.tar.gz")))
(s "ls")
(s "pwd")


;; TF2 setup
(s "apt-get" "-y" "install" "libstdc++6" "libcurl3-gnutls" "wget" "libncurses6" "bzip2" "unzip" "vim" "nano")

(def server-dir "/tf2")
;; ls directories
(s "ls" "-l" "/")
(when-not (fs/exists? server-dir)
  (s "mkdir" "-p" server-dir))

(s "wget" "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" "-O" "steamcmd.tar.gz")

(s "tar" "-xzf" "steamcmd.tar.gz" "-C" server-dir)

(s "rm" "steamcmd.tar.gz")

(s "cd" server-dir)
