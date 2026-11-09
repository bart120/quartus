#!/bin/sh
# Connexion d'un conteneur à Jenkins en tant qu'agent (WebSocket, pas de port 50000 nécessaire).
# Tant que JENKINS_SECRET est vide (TP 0), le conteneur reste simplement disponible
# pour lancer des commandes à la main : docker compose exec hdl-sim bash
if [ -z "$JENKINS_SECRET" ]; then
    echo "JENKINS_SECRET vide : mode poste de développement (pas de connexion à Jenkins)."
    exec sleep infinity
fi
mkdir -p /home/jenkins/agent
until curl -fsSo /tmp/agent.jar "$JENKINS_URL/jnlpJars/agent.jar"; do
    echo "Jenkins injoignable sur $JENKINS_URL, nouvel essai dans 5 s..."
    sleep 5
done
exec java -jar /tmp/agent.jar -url "$JENKINS_URL" -secret "$JENKINS_SECRET" \
     -name "$JENKINS_AGENT_NAME" -webSocket -workDir /home/jenkins/agent
