{-# LANGUAGE CPP #-}

module LocalTimeZone
    ( TZ
    , loadLocalTZ
    , localTimeToUTCTZ
    , utcToLocalTimeTZ
    ) where

import Data.Time.Zones (TZ, localTimeToUTCTZ, utcToLocalTimeTZ)

#if defined(mingw32_HOST_OS)
import Data.Char (isSpace)
import Data.List (dropWhileEnd)
import qualified Data.Time.Zones as Zones
import System.Directory (doesFileExist)
import System.Environment (getExecutablePath, lookupEnv)
import System.Exit (ExitCode(..))
import System.FilePath ((</>), takeDirectory)
import System.Process (readProcessWithExitCode)

import WindowsTimeZone (windowsToIana)

-- The tz package's loadLocalTZ assumes a Unix zoneinfo installation. Windows
-- uses different time-zone identifiers, so translate the system identifier to
-- IANA and load the zoneinfo file shipped beside the executables.
loadLocalTZ :: IO TZ
loadLocalTZ = do
    configuredTimeZone <- lookupEnv "TZ"
    ianaName <- case configuredTimeZone of
        Just ""   -> return "UTC"
        Just name -> return name
        Nothing   -> detectWindowsTimeZone
    loadBundledTimeZone ianaName

detectWindowsTimeZone :: IO String
detectWindowsTimeZone = do
    (exitCode, stdout, stderr) <- readProcessWithExitCode "tzutil.exe" ["/g"] ""
    case exitCode of
        ExitSuccess ->
            let windowsName = trim stdout
            in case windowsToIana windowsName of
                Just ianaName -> return ianaName
                Nothing -> ioError . userError $
                    "Unsupported Windows time zone '" ++ windowsName ++
                    "'. Set TZ to an IANA name such as Europe/Berlin."
        ExitFailure code -> ioError . userError $
            "Could not detect the Windows time zone (tzutil exit code " ++
            show code ++ "): " ++ trim stderr

loadBundledTimeZone :: String -> IO TZ
loadBundledTimeZone ianaName = do
    configuredDirectory <- lookupEnv "TZDIR"
    zoneInfoDirectory <- case configuredDirectory of
        Just directory -> return directory
        Nothing -> do
            executable <- getExecutablePath
            return $ takeDirectory (takeDirectory executable) </> "share" </> "zoneinfo"
    let zoneInfoFile = zoneInfoDirectory </> ianaName
    exists <- doesFileExist zoneInfoFile
    if exists
        then Zones.loadTZFromFile zoneInfoFile
        else ioError . userError $
            "Time-zone data file not found: " ++ zoneInfoFile

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace
#else
import Data.Time.Zones (loadLocalTZ)
#endif
