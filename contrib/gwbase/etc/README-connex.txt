https://github.com/geneanet/geneweb/issues/252

==============================================================================

ipfix commented on 16 May 2015

Il existe un utilitaire pour les bases où la création de famille n'est possible
qu'en partant d'un membre de la base, et qui permet :

- des statistiques sur la connexité de la base

- l'élimination des branches isolées.

Préalable :

Faut que GeneWeb soit compilé. cd gwbase/etc et "make".

Si ça ne compile pas, c'est que GeneWeb n'est pas en ../../geneweb par rapport à
gwbase/etc et il suffit d'éditer le Makefile et de changer la ligne
GWB=../../geneweb en ce qui convient, chemin absolu ou relatif.

Ça compile un certain nombre d'utilitaires (à explorer) Celui qui nous intéresse s'appelle
"connex". La compilation fabrique un exécutable "connex.opt". Taper ./connex.opt
-help pour avoir les options. Il n'y en a pas beaucoup. Utilisation typique :
./connex.opt roglo.gwb ou même : ./connex.opt roglo Ça affiche les composantes
connexes qu'il trouve, par taille décroissante. S'il en trouve une plus petite
que la précédente, il n'affiche pas les plus grosses qu'il trouve, sauf si on
met l'option -a. On peut essayer directement sur une base en service : par
défaut, la base est consultée sans aucune modif. Connex lit la base linéairement
et ne cherche que les composantes connexes plus petites, sauf si on utilise
l'option -a.

En complément, le script link.pl permet de fabriquer un fichier au
format wiki de GeneWeb : Utilisation : /data/src/gwbase/etc/connex.opt -a
/home/roglo/base/roglo |perl link.pl |sort -r
>../roglo.gwb/base_d/notes_d/Admin/connex.txt met les liens sur les différentes
branches, et les statistiques dans la page wiki Admin:connex Pour la suppression
des branches indésirables, utiliser les statistiques pour dimensionner
correctement la requête : perl -e 'for ($i=0;$i<1004;$i++) {print
"y\n";}'|/data/src/gwbase/etc/connex.opt -del 1 /home/roglo/base/roglo


==============================================================================

GuillaumeBrochu commented on 24 January 2016

Fonctionne à merveille, mais il faut éviter le répertoire parent ".." quand on spécifie la base à utiliser, sinon erreur.

Exemple (en supposant qu'on ait copié connex.opt dans gw/ avec les autres exécutables):

Fonctionne bien:

./bin/distribution/gw/connex.opt bases/test

Produit une erreur:

./bin/distribution/gw/connex.opt ../geneweb/bases/test
*** secure rejects open ../geneweb/bases/test.gwb/patches
*** secure rejects open ../geneweb/bases/test.gwb/base
Fatal error: exception Sys_error("invalid access")


