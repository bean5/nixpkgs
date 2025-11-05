{
  lib,
  stdenv,
  callPackage,
  vscode-generic,
  fetchurl,
  appimageTools,
  undmg,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;
  finalCommandLineArgs = "--update=false " + commandLineArgs;

  sources = {
    # Get using `cat Cursor-*.AppImage | openssl dgst -sha256 -binary | openssl base64 | sed 's/^/sha256-/'`
    x86_64-linux = fetchurl {
      url = "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.1";
      hash = "sha256-VPGl04VT8wRDxb351h/y0O+Ui2T0Qk/sHaaFjkiYa2s=";
    };
    aarch64-linux = fetchurl {
       url = "https://downloads.cursor.com/production/9675251a06b1314d50ff34b0cbe5109b78f848cd/linux/arm64/Cursor-2.1.46-aarch64.AppImage";
       hash = "sha256-96zL0pmcrEyDEy8oW2qWk6RM8XGE4Gd2Aa3Hhq0qvk0=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/823f58d4f60b795a6aefb9955933f3a2f0331d7b/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-A13mVAw8mgjGlGegAzkeUi536keZwcJZkbO4ZzfMmXs=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/823f58d4f60b795a6aefb9955933f3a2f0331d7b/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-Pc1pG1Vj9bf8H6Gt2bR8JANo/6oZza+L3Zlrihpg1dk=";
    };
  };

  source = sources.${hostPlatform.system};
in
(callPackage vscode-generic rec {
  inherit useVSCodeRipgrep;
  commandLineArgs = finalCommandLineArgs;

  # Get this from the portion from the filename AppImage
  version = "2.1.46";
  pname = "cursor";

  # You can find the current VSCode version in the About dialog:
  # workbench.action.showAboutDialog (Help: About)
  vscodeVersion = "1.99.3";

  executableName = "cursor";
  longName = "Cursor";
  shortName = "cursor";
  libraryName = "cursor";
  iconName = "cursor";

  src =
    if hostPlatform.isLinux then
      appimageTools.extract {
        inherit pname version;
        src = source;
      }
    else
      source;

  sourceRoot =
    if hostPlatform.isLinux then "${pname}-${version}-extracted/usr/share/cursor" else "Cursor.app";

  tests = { };

  updateScript = ./update.sh;

  # Editing the `cursor` binary within the app bundle causes the bundle's signature
  # to be invalidated, which prevents launching starting with macOS Ventura, because Cursor is notarized.
  # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
  dontFixup = stdenv.hostPlatform.isDarwin;

  # Cursor has no wrapper script.
  patchVSCodePath = false;

  meta = {
    description = "AI-powered code editor built on vscode";
    homepage = "https://cursor.com";
    changelog = "https://cursor.com/changelog";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [
      aspauldingcode
      prince213
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ]
    ++ lib.platforms.darwin;
    mainProgram = "cursor";
  };
}).overrideAttrs
  (oldAttrs: {
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ]) ++ lib.optionals hostPlatform.isDarwin [ undmg ];

    passthru = (oldAttrs.passthru or { }) // {
      inherit sources;
    };
  })
