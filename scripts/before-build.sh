#!/bin/sh

unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)
        echo '"-framework CoreFoundation -framework Security"' > src/freeton_ocaml_rust/dune.include
        echo MacOSX Detected
        ;;
    *)
        echo '""' > src/freeton_ocaml_rust/dune.include
        echo MacOSX Not Detected
        ;;
esac
