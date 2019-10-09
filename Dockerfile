FROM mhart/alpine-node:5.11
ENV \
 APK_PKGS=’git openssh python build-base’ \
 NPM_GLOBAL_PKGS=’bower ember-cli node-gyp’
COPY . /app
RUN \
 #
 # Install Github SSH config
 #
 mkdir -p ~/.ssh && \
 chmod 700 ~/.ssh && \
 cp /app/github-ssh/deploy_key ~/.ssh/id_rsa && \
 chmod 0600 ~/.ssh/id_rsa && \
 cat /app/github-ssh/known_hosts >> ~/.ssh/known_hosts && \
 cat /app/github-ssh/ssh_config >> ~/.ssh/ssh_config && \
 chmod 0644 ~/.ssh/known_hosts && \
 #
 # Install global dependencies
 #
 apk --no-cache add $APK_PKGS && \
 npm install -g $NPM_GLOBAL_PKGS && \
 #
 # Build app
 #
 cd /app && \
 bower install --allow-root && \
 npm install && \
 ember build --environment=production && \
 ./git-version.sh && \
 #
 # Build server
 #
 cd /app/dist && npm install && \
 cd /app/server && npm install && \
 #
 # Trim server node_modules
 #
 find \
   /app/dist/node_modules \
   /app/server/node_modules \
   \( \
     \( -type d -name test -o -name .bin \)\
     -o \( -type f -name *.md -o -iname LICENSE -o -name *.map \) \
   \) -exec rm -rf ‘{}’ + \
 && \
 #
 # Uninstall global dependencies
 #
 apk del $APK_PKGS && \
 npm uninstall -g $NPM_GLOBAL_PKGS && \
 #
 # Cleanup app
 #
 rm -rf \
   /app/bower_components \
   /app/node_modules \
   /app/tmp \
 && \
 #
 # Cleanup bower
 #
 rm -rf \
   ~/.cache/bower \
   ~/.config/configstore \
 && \
 #
 # Cleanup npm
 #
 rm -rf \
   ~/.node-gyp \
   ~/.npm \
   /tmp/* \
 && \
 #
 # Cleanup apk
 #
 rm -rf \
   /etc/apk/* \
   /etc/ssl \
   /lib/apk/* \
 && \
 #
 # Cleanup Github SSH config
 #
 rm -rf \
   ~/.ssh \
 && \
 echo ‘Done’
EXPOSE 3000
CMD [“node”, “/app/server/server.js”]