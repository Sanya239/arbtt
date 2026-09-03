{-# LANGUAGE CPP #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module CommonStartup where

#ifdef WIN32
import Control.Monad (void)
import Foreign.C.Types (CInt(..), CUInt(..))
import System.IO (hSetEncoding, stderr, stdout, utf8)
#else
import System.Locale.SetLocale
#endif

#ifdef WIN32
foreign import ccall unsafe "SetConsoleCP"
        c_SetConsoleCP :: CUInt -> IO CInt

foreign import ccall unsafe "SetConsoleOutputCP"
        c_SetConsoleOutputCP :: CUInt -> IO CInt
#endif

commonStartup :: IO ()
commonStartup = do
#ifdef WIN32
        -- GHC otherwise inherits the current Windows code page.  Besides
        -- displaying mojibake, that can make writing a Unicode window title
        -- fail altogether when stdout is redirected.
        void $ c_SetConsoleCP 65001
        void $ c_SetConsoleOutputCP 65001
        hSetEncoding stdout utf8
        hSetEncoding stderr utf8
#else
        setLocale LC_ALL (Just "") 
#endif
        return ()
