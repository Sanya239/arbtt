module Capture.Win32 where

import Data
import qualified Data.MyText as T
import Data.Maybe (listToMaybe)
import System.FilePath.Windows (takeFileName)

import Graphics.Win32.Window.Extra

setupCapture :: IO ()
setupCapture = do
        return ()

captureData :: IO CaptureData
captureData = do
        foreground <- getForegroundWindow
        foregroundPid <- getWindowProcessId foreground
        titles <- fetchWindowTitles

        let exactForeground = any (\(h, _, _, _) -> h == foreground) titles
            fallbackForeground = listToMaybe
                [ h | (h, pid, _, _) <- titles, pid == foregroundPid ]
            isActive h = h == foreground ||
                (not exactForeground && Just h == fallbackForeground)
            winData =
                [ fromWDv0 (isActive h, T.pack title,
                            T.pack (takeFileName program))
                | (h, _, title, program) <- titles
                ]

        it <- fromIntegral `fmap` getIdleTime

        return $ CaptureData winData it (T.pack "")
