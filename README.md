# Gravae FFmpeg Mobile

Pipeline reproduzível dos binários LGPL usados pelo editor local dos apps
Gravae e Replayme. Este repositório não contém código de produto nem depende do
Argos.

## O que é produzido

- Android: AAR Maven com `arm64-v8a`, `armeabi-v7a` e `x86_64`.
- iOS: XCFrameworks para aparelho arm64 e simulador arm64.
- manifesto de release, checksums, relatório de capacidades, logs de build e
  código-fonte correspondente.

O aplicativo baixa esses pacotes somente durante o prebuild/EAS. O FFmpeg é
incorporado ao AAB/IPA e nunca é baixado pelo usuário final.

## Versões e licença

As versões estão fixadas em [`config/build.env`](config/build.env). O build não
usa `--enable-gpl`, x264, x265, fdk-aac ou outras bibliotecas proibidas pela
política em [`config/forbidden-components.txt`](config/forbidden-components.txt).

Os scripts deste repositório usam MIT. FFmpeg, FFmpegKit, OpenSSL e demais
dependências preservam suas próprias licenças. Cada release publica o código e
os patches correspondentes. O uso em loja ainda deve passar por revisão
jurídica antes da primeira publicação.

## Build local

Android exige Linux, Android SDK e o NDK configurado em `ANDROID_NDK_ROOT`:

```bash
./scripts/build-android.sh
```

iOS exige macOS e Xcode:

```bash
./scripts/build-ios.sh
```

Os pacotes finais ficam em `dist/`. Builds oficiais são criados apenas por tags
`mobile-ffmpeg-*` no workflow `release.yml`.

## Publicação

1. Atualize `config/build.env` e os patches.
2. Execute os validadores locais aplicáveis.
3. Crie a tag `mobile-ffmpeg-X.Y.Z`.
4. Aguarde os builds Android/iOS e a publicação da release.
5. Copie o `artifact-manifest.json` da release para o repositório mobile.
6. Rode `yarn install:video-editor-ffmpeg --platform all` no mobile.

Nunca substitua um arquivo de uma release existente. Uma alteração de fonte,
toolchain, patch ou configuração exige nova versão.
