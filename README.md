
# Laboratoire HTTP - Lionel Widmer / Kevin Pradervand

## Informations générales
Docker tourne sur une VM Linux (une VM 'poubelle', pour ne pas polluer le laptop). Cette VM a l'adresse IP 10.0.1.15, donc tous les accès WEB se feront vers cette IP.

## Partie 1
Cette partie consiste simplement à créer une image Docker qui déserve du contenu static.
Le Dockerfile se base sur une image Apache de base (Apache + PHP), et nous copions le contenu HTML au bon endroit dans l'image grâce au Dockerfile.
Pas besoin de faire de commentaires sur le Dockerfile, il est très simple et ne contient pas de spécialités.
Voici les étapes de la construction de l'image :

### Manipulations
Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git
```
$ git checkout fb-apache-static
```

Construire l'image
```
$ cd docker-images/apache-static-image
$ docker build -t res/apache_php .
```

Exécuter un container avec cette image
L'option -p permet de binder un port de notre machine locale vers un port du container afin qu'on puisse accéder au container sur ce port depuis l'extérieur de Docker
L'option -d lance le container en arrière-plan.
L'option --name permet de donner un nom au container
```
$ docker run -p 8080:80 -d --name apache_static res/apache_php
```

### Ça fonctionne
L'URL suivante est accessible : http://10.0.1.15:8080




## Partie 2
Cette partie consiste à faire un serveur HTTP desservant du contenu dynamique (dynamique dans le sens qu'à chaque rafraîchissement de la page, un contenu différent est affiché).
Ce serveur a été fait avec express.js

### Code express.js
Le code JS est assez simple et a été fait en suivant les instructions de M. Liechti dans les webcasts.
Les packages npm ont été installés (les dépendances sont dans le fichier packages.json, qui est automatiquement mis à jour lorsqu'on installe le package via npm.

### Dockerfile
Le Dockerfile fonctionne sur le même principe que pour l'étape 1 sauf qu'on part d'une image Node et non d'une image Apache, et qu'on lance la commande Node appelant index.js (dernière ligne du Dockerfile) :
CMD ["node", "/opt/app/index.js"]

### Manipulations
Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git
```
$ git checkout fb-ajax-jquery
```

Construire l'image
```
$ cd docker-images/express-image
$ docker build -t res/express_datas .
```

Exécuter un container avec cette image
L'option -p permet de binder un port de notre machine locale vers un port du container afin qu'on puisse accéder au container sur ce port depuis l'extérieur de Docker. Ici on bind le port 8080 sur le port 3000 du container, comme express tourne sur le port 3000
L'option -d lance le container en arrière-plan.
L'option --name permet de donner un nom au container
```
$ docker run -p 8080:3000 -d --name express_dynamic res/express_datas
```

### Ça fonctionne
L'URL suivante est accessible : http://10.0.1.15:8080




## Partie 3
Cette partie consiste à créer un reverse proxy Apache, qui redirige les requêtes sur 2 containers différents, en fonction de l'URL passée par le client dans son browser

### Prérequis
Ajouter l'entrée suivante dans le fichier hosts de la machine depuis laquelle on utilise notre browser pour faire les tests :
```
$ echo "10.0.1.15	res.heig-vd.ch" >> /etc/hosts
```

### Dockerfile
Le Dockerfile se base sur l'image Apache et contient plusieurs choses :
1. Copie du dossier conf dans /etc/apache2 dans l'image
2. Activation des modules Apache nécessaires à la configuration du reverse proxy : mod_proxy et mod_proxy_http
3. Activation desd virtual hosts 000-* et 001-* (le 000 est un virtual host vide utilisé pour sécuriser notre Apache, et le 001 contient notre reverse proxy)

### Fichier de configuration Apache 001-reverse-proxy.conf
Ce fichier contient la confituration du reverse proxy. La ligne 'ServerName' contient le FQDN pour lequel le serveur doit utiliser ce virtual host (res.heig-vd.ch).
Les autres directives définissent vers quel node rediriger les requêtes en fonction de l'URL passée par le client.
Voici le fichier :
```
<VirtualHost *:80>
	ServerName res.heig-vd.ch

	ProxyPass "/api/students/" "http://172.17.0.3:3000/"
	ProxyPassReverse "/api/students/" "http://172.17.0.3:3000/"

	ProxyPass "/" "http://172.17.0.2:80/"
	ProxyPassReverse "/" "http://172.17.0.2:80/"
</VirtualHost>
```

### Manipulations
Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git
```
$ git checkout fb-apache-reverse-proxy
```

Construire l'image
```
$ cd docker-images/apache-reverse-proxy
$ docker build -t res/apache_rp_static .
```

Exécuter des containers dans l'ordre suivant car il faut absolument que le serveur statique se prenne l'IP 172.17.0.2 et le serveur dynamique l'IP 172.17.0.3, puis exécuter le reverse poxy (avec port binding) comme ci-dessous :
```
$ docker run -d --name apache_static res/apache_php
$ docker run -d --name express_dynamic res/express_datas
$ docker run -d --name apache_rp -p 8080:80 res/apache_rp_static
```

### Ça fonctionne
L'URL suivante est accessible : http://res.heig-vd.ch:8080/
L'URL suivante est accessible : http://res.heig-vd.ch:8080/api/students/



## Partie 4
Le but de cette partie est que le site statique se mette à jour en appelant le site dynamique pour récupérer des données et les afficher.
C'est fait en JavaScript / AJAX.

### Dockerfile
Le Dockerfile est strictement identique au Dockerfile de la partie 1 !

### Modifications du code HTML
Le fichier index.html a été modifié afin d'inclure un nouveau fichier JavaScript (qui contiendra notre requête AJAX). Le bloc ci-dessous a été ajoutée à la fin du fichier index.html :
```
    <!-- Custom script to load students -->
    <script src="js/customDataLoader.js"></script>
```

### Contenu du fichier js/customDataLoader.js
Le fichier js contient le contenu suivant, qui effectue une requête AJAX à notre API toutes les 2 secondes :
```
$(function() {
	console.log("Loading data");

	function loadData() {
		$.getJSON( "/api/students/", function (companies) {
			console.log(companies);
			var message = "Nobody is here";
			if (companies.length > 0 ) {
				message = companies[0].company + " - " + companies[0].domain;
			}
			$(".text-faded").text(message);
		});
	};

	loadData();
	setInterval( loadData, 2000);
});
```

### Manipulations
Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git 
```
$ git checkout fb-ajax-jquery
```

Construire l'image
```
$ cd docker-images/apache-static-image
$ docker build -t res/apache_php .
```

Exécuter des containers dans l'ordre suivant car il faut absolument que le serveur statique se prenne l'IP 172.17.0.2 et le serveur dynamique l'IP 172.17.0.3, puis exécuter le reverse poxy (avec port binding) comme ci-dessous :
```
$ docker run -d --name apache_static res/apache_php
$ docker run -d --name express_dynamic res/express_datas
$ docker run -d --name apache_rp -p 8080:80 res/apache_rp_static
```

### Ça fonctionne
L'URL suivante est accessible : http://res.heig-vd.ch:8080/
Et on remarque qu'au milieu de la page toutes les 2 secondes un élément est mis à jour.




## Partie 5
Le but de cette partie est de configurer automatiquement le fichier 001-reverse-proxy.conf avec l'IP du serveur statique et du serveur dynamique, sans avoir à recréer l'image à chaque fois qu'une des IP change.
Docker permet de passer des variables lors de la construction d'un container (lorsqu'on exécute la commande 'docker run'). C'est cette méthode qui est utilisée dans cette partie afin de configurer dynamiquement les IP's dans le fichier de configuration.
Un script PHP est utilisé afin de prendre en compte les variables d'environnement et de construire le fichier 001-reverse-proxy.configuration

### Dockerfile
Le Dockerfile est le suivant :
```
FROM php:7.2-apache

RUN apt-get update && apt-get install -y vim

COPY conf/ /etc/apache2
COPY apache2-foreground /usr/local/bin/

RUN mkdir -p /var/apache2
COPY templates /var/apache2/templates/

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```
C'est donc l'image Apache qui est l'image de base.
Ensuite on installe vim (c'est un détail, c'était pour les tests).
Le fichier apache2-foreground a été adapté. C'est pour ça qu'on doit le copier (copier le fichier modifié) à l'endroit original afin que lors du lancement du conainer, la version modifiée du scropt soit appelée.
Le dossier templates est un dossier qui contient le script PHP qui va construire le fichier 001-reverse-proxy.configuration.
Ensuite, on active les modules proxy et proxy_http.
Puis finalement on active les 2 virtual hosts.

### Contenu du fichier templates/config-template.php
C'est un simple script PHP qui va récupérer le contenu des 2 variables d'environnement qu'on a passées lors de la construction du container, et les injecter dans les directives ProxyPass et ProxyPassReverse.
```
<?php
	$STATIC_APP = getenv('STATIC_APP');
	$DYNAMIC_APP = getenv('DYNAMIC_APP');
?>

<VirtualHost *:80>
	ServerName res.heig-vd.ch

	ProxyPass '/api/students/' 'http://<?php print "$DYNAMIC_APP" ?>/'
	ProxyPassReverse '/api/students/' 'http://<?php print "$DYNAMIC_APP" ?>/'

	ProxyPass '/' 'http://<?php print "$STATIC_APP" ?>/'
	ProxyPassReverse '/' 'http://<?php print "$STATIC_APP" ?>/'
</VirtualHost>
```

### Manipulations
Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git 
```
$ git checkout fb-dynamic-configuration
```

Construire l'image
```
$ cd docker-images/apache-reverse-proxy
$ docker build -t res/apache_rp .
```

Exécuter plusieurs containers res/apache_php et plusieurs containers res/express-datas afin d'être sûrs que les IP's ne soient pas les mêmes que lors des différents étapes :
```
$ docker run -d res/apache_php
$ docker run -d res/apache_php
$ docker run -d res/apache_php
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d --name apache_static res/apache_php
$ docker run -d --name express_dynamic res/express_datas
```

Récupérer l'IP du container apache_static et express_dynamic, et exécuter le reverse proxy avec ces valeurs
```
$ ip_static=`docker inspect apache_static | grep IPAddress | grep -v Secondary | head -1 | cut -d":" -f2 | cut -d"\"" -f2`
$ ip_dynamic=`docker inspect express_dynamic | grep IPAddress | grep -v Secondary | head -1 | cut -d":" -f2 | cut -d"\"" -f2`
$ docker run -d --name apache_rp -p 8080:80 -e STATIC_APP=${ip_static}:80 -e DYNAMIC_APP=${ip_dynamic}:3000 res/apache_rp
```

### Ça fonctionne
L'URL suivante est accessible : http://res.heig-vd.ch:8080/
Et on remarque qu'au milieu de la page toutes les 2 secondes un élément est mis à jour.



## Partie 6 - load balancing
Le load balancer est très simple à mettre en place. Uniquement le fichier 001-reverse-proxy.conf à modifier (nous l'avons renommé 001-load-balancer.conf par la même occasion)

### Dockerfile
Il faut activer des modules supplémentaires afin de supporter le load balancer. Voici le Dockerfile complet :
```
FROM php:7.2-apache

COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers
RUN a2ensite 000-* 001-*
```

### Fichier de configuration Apache conf/sites-available/001-load-balancer.config
Voici le contenu :
```
<VirtualHost *:80>
        ServerName res.heig-vd.ch

	<Proxy "balancer://static/">
		BalancerMember "http://172.17.0.5:80"
		BalancerMember "http://172.17.0.6:80"
		BalancerMember "http://172.17.0.7:80"
	</Proxy>

	Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/api/students/" env=BALANCER_ROUTE_CHANGED
	<Proxy "balancer://dynamic/">
		BalancerMember "http://172.17.0.2:3000" route=1
		BalancerMember "http://172.17.0.3:3000" route=2
		BalancerMember "http://172.17.0.4:3000" route=3
		ProxySet stickysession=ROUTEID
	</Proxy>

	ProxyPass        "/api/students/" "balancer://dynamic/"
	ProxyPassReverse "/api/students/" "balancer://dynamic/"

	ProxyPass        "/" "balancer://static/"
	ProxyPassReverse "/" "balancer://static/"

</VirtualHost>
```

### Manipulations
Comme les IP's sont hardcodées il faut faire attention de démarrer les nodes dans le bon sens...

Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git
```
$ git checkout fb-static-load-balancing
```

Construire l'image et reconstruire l'image res/express_datas
```
$ cd docker-images/apache-load-balancing
$ docker build -t res/apache_lb  .
$ cd ../express-image
$ docker build -t res/express_datas  .
```

Exécuter 3 containers res/apache_php et 3 containers res/express-datas :
```
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d res/apache_php
$ docker run -d res/apache_php
$ docker run -d res/apache_php

```

Exécuter le load balancer
```
$ docker run -d --name apache_lb -p 8080:80 res/apache_lb
```

### Ça fonctionne
L'URL suivante est disponible : http://res.heig-vd.ch:8080/
L'URL suivante est disponible : http://res.heig-vd.ch:8080/api/students/
De plus on remarque en rafraîchissant la page http://res.heig-vd.ch:8080/api/students/ que le hostname (le hostname du container Docker) change (dans le payload JSON renvoyé).




## Partie 7 - load balancing sticky sessions
Setup identique que pour le load balancer de l'étape 6, sauf qu'il faut un peu modifier le fichier 001-load-balancing.conf

### Dockerfile
Idem que pour l'étape 6

### Fichier de configuration Apache conf/sites-available/001-load-balancer.config
Cette configuraion du reverse proxy va simplement envoyer un cookie au client la première fois qu'il ouvre une session. Ce cookie contient un numéro, qui est le numéro du noeud du load balancer auquel les requêtes sont envoyées. Du fait de cette implémentation, un client communiquera toujours avec le même noeud.
Voici le contenu :
```
<VirtualHost *:80>
        ServerName res.heig-vd.ch

	<Proxy "balancer://static/">
		BalancerMember "http://172.17.0.5:80"
		BalancerMember "http://172.17.0.6:80"
		BalancerMember "http://172.17.0.7:80"
	</Proxy>

	Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/api/students/" env=BALANCER_ROUTE_CHANGED
	<Proxy "balancer://dynamic/">
		BalancerMember "http://172.17.0.2:3000" route=1
		BalancerMember "http://172.17.0.3:3000" route=2
		BalancerMember "http://172.17.0.4:3000" route=3
		ProxySet stickysession=ROUTEID
	</Proxy>

	ProxyPass        "/api/students/" "balancer://dynamic/"
	ProxyPassReverse "/api/students/" "balancer://dynamic/"

	ProxyPass        "/" "balancer://static/"
	ProxyPassReverse "/" "balancer://static/"

</VirtualHost>
```

### Manipulations
Comme les IP's sont hardcodées il faut faire attention de démarrer les nodes dans le bon sens...

Arrêter tous les containers Docker et les supprimer
```
$ docker rm -f `docker ps -qa`
```

Changer de branche Git
```
$ git checkout fb-load-balancer-rr-ss
```

Construire l'image
```
$ cd docker-images/apache-load-balancing-rr-ss
$ docker build -t res/apache_lb_rr_ss  .
```

Exécuter 3 containers res/apache_php et 3 containers res/express-datas :
```
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d res/express_datas
$ docker run -d res/apache_php
$ docker run -d res/apache_php
$ docker run -d res/apache_php

```

Exécuter le load balancer
```
$ docker run -d --name apache_lb_rr_ss -p 8080:80 res/apache_lb_rr_ss
```

### Ça fonctionne
L'URL suivante est disponible : http://res.heig-vd.ch:8080/
L'URL suivante est disponible : http://res.heig-vd.ch:8080/api/students/
De plus on remarque en rafraîchissant la page http://res.heig-vd.ch:8080/api/students/ que le hostname (le hostname du container Docker) ne change pas (dans le payload JSON renvoyé).
Egalement on remarque dans la liste de nos cookies que l'URL res.heig-vd.ch nous a renvoyé un cookie.
