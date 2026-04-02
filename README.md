# ATELIER FROM IMAGE TO CLUSTER

Cet atelier consiste à **industrialiser le cycle de vie d'une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l'aide d'**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.

---

## Architecture cible

![Architecture cible](Architecture_cible.png)

Le flux de travail suit cette logique :

1. **Packer** construit une image Docker Nginx customisée embarquant notre fichier `index.html`
2. L'image est **importée dans le cluster K3d**
3. **Ansible** déploie l'application sur Kubernetes (Deployment + Service)
4. L'application est accessible via **port-forward** sur le port 8081

---

## Prérequis

- Un compte GitHub avec accès à **GitHub Codespaces**
- Avoir forké ce repository

---

## Séquence 1 : Création du Codespace

1. **Forkez ce repository** depuis GitHub
2. Depuis l'onglet **[Code]** de votre fork, cliquez sur **"Create codespace on main"**

Le Codespace démarre avec un environnement Linux complet prêt à l'emploi.

---

## Séquence 2 : Création du cluster Kubernetes K3d

Dans le terminal du Codespace, exécutez les commandes suivantes :

**Installation et création du cluster :**

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

```bash
k3d cluster create lab --servers 1 --agents 2
```

**Vérification :**

```bash
kubectl get nodes
```

Vous devriez voir 1 server et 2 agents avec le statut `Ready`.

**Test avec Docker Mario (optionnel) :**

```bash
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```

Rendez le port 8080 **public** dans l'onglet **PORTS** du Codespace et ouvrez l'URL.

---

## Séquence 3 : Déploiement de l'image customisée (Packer + Ansible)

### Outils utilisés

| Outil | Rôle |
|-------|------|
| **Packer** | Construit une image Docker Nginx customisée contenant notre `index.html` |
| **Ansible** | Déploie automatiquement l'image sur le cluster K3d via des manifestes Kubernetes |
| **K3d** | Cluster Kubernetes léger tournant dans Docker |
| **Makefile** | Automatise l'ensemble du processus en une seule commande |

### Structure du projet

```
Image_to_Cluster/
├── index.html                  # Page web (SVG maison + soleil)
├── Makefile                    # Automatisation des commandes
├── README.md                   # Ce fichier
├── Architecture_cible.png      # Schéma de l'architecture
├── packer/
│   └── nginx-custom.pkr.hcl   # Template Packer (build de l'image Docker)
└── ansible/
    └── deploy.yml              # Playbook Ansible (déploiement K8s)
```

### Installation des dépendances

```bash
make install
```

Cette commande installe Packer, Ansible, la collection `kubernetes.core` et le module Python `kubernetes`.

### Déploiement complet

Si les dépendances sont déjà installées (Packer, Ansible, etc.), lancez :

```bash
make build import deploy forward
```

Cette commande enchaîne automatiquement :

1. **`make build`** — Packer construit l'image `nginx-custom:latest` (Nginx Alpine + `index.html`)
2. **`make import`** — L'image est importée dans le cluster K3d `lab`
3. **`make deploy`** — Ansible crée le namespace `nginx-app`, le Deployment (2 replicas) et le Service NodePort
4. **`make forward`** — Un port-forward est lancé sur le port **8081**

> **Première utilisation ?** Lancez `make all` pour tout faire d'un coup (installation incluse).

### Accéder à l'application

Après le déploiement :

1. Allez dans l'onglet **PORTS** du Codespace
2. Trouvez le port **8081**
3. **⚠️ Changez la visibilité du port en "Public"** (clic droit → Port Visibility → Public)
4. Cliquez sur l'URL pour ouvrir l'application dans votre navigateur

> **Important :** Si vous obtenez une erreur 404, vérifiez que le port 8081 est bien en visibilité **Public** et non "Private".

### Vérification manuelle

Pour vérifier que tout tourne correctement :

```bash
# Vérifier les pods
kubectl get pods -n nginx-app

# Vérifier le service
kubectl get svc -n nginx-app

# Vérifier l'image Docker
docker images | grep nginx-custom
```

### Nettoyage

Pour supprimer le déploiement et l'image :

```bash
make clean
```

---

## Séquence 4 : Détails techniques

### Packer — `packer/nginx-custom.pkr.hcl`

Packer utilise le builder **Docker** pour :
- Partir de l'image de base `nginx:alpine`
- Copier le fichier `index.html` dans `/usr/share/nginx/html/`
- Taguer l'image résultante `nginx-custom:latest`

### Ansible — `ansible/deploy.yml`

Le playbook Ansible crée 3 ressources Kubernetes :
- Un **Namespace** `nginx-app` pour isoler l'application
- Un **Deployment** avec 2 replicas du conteneur `nginx-custom:latest` (avec `imagePullPolicy: Never` car l'image est locale)
- Un **Service** de type NodePort exposant le port 80

### Makefile

Le Makefile offre les cibles suivantes :

| Commande | Description |
|----------|-------------|
| `make all` | Exécute tout : install + build + import + deploy + forward |
| `make install` | Installe Packer, Ansible et les dépendances |
| `make build` | Build l'image Docker via Packer |
| `make import` | Importe l'image dans K3d |
| `make deploy` | Déploie l'app via Ansible |
| `make forward` | Lance le port-forward sur le port 8081 |
| `make clean` | Supprime le namespace et l'image |

---

## Évaluation

| Critère | Points |
|---------|--------|
| Repository exécutable sans erreur majeure | /4 |
| Fonctionnement conforme au scénario annoncé | /4 |
| Degré d'automatisation (Makefile) | /4 |
| Qualité du README | /4 |
| Processus de travail (commits, cohérence) | /4 |
| **Total** | **/20** |