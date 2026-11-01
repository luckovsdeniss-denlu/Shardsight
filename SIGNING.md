# Fixed signing key (so new builds install over old ones)

Without this, CI signs every build with a fresh throwaway key, and Android refuses to update
an app signed with a different key: you have to uninstall first. Do this once:

1. On your own computer (needs a JDK), create a key. Use the alias `androiddebugkey`, and give
   the key the same password as the keystore:

       keytool -genkeypair -v -keystore shardsight.keystore -alias androiddebugkey \
         -keyalg RSA -keysize 2048 -validity 10000 -storetype pkcs12

2. Turn it into one line of text:

       base64 -w0 shardsight.keystore          # macOS: base64 -i shardsight.keystore

3. In the GitHub repo: Settings > Secrets and variables > Actions > New repository secret.
   Add two secrets:
   - `ANDROID_KEYSTORE_BASE64`: the text from step 2
   - `ANDROID_KEYSTORE_PASSWORD`: the password you chose

4. Keep `shardsight.keystore` and the password somewhere safe. Never commit them. If you lose
   them, you can't ship updates that install over existing installs.

The next build prints "Using the fixed signing key" in the workflow log. Uninstall once more,
then every later build installs as an update.
