module Main where

import Distribution.Simple (defaultMain)

-- Windows installer creation is intentionally separate from the Cabal build.
-- See scripts/build-windows-installer.ps1 and .github/workflows/windows.yml.
main :: IO ()
main = defaultMain
