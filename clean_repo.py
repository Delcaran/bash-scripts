#!/usr/bin/python

import string
from os import remove
from os import listdir
from os.path import isfile, join

dirRepo = "/home/delcaran/Slackware/SBo"


mypkg = {}

for x in range(2):
	myfiles = [ f for f in listdir(dirRepo) if isfile(join(dirRepo,f)) ]
	for pkg in myfiles:
		pkg_part = string.split(pkg, '_SBo.tgz')
		name, version, arch, build = string.rsplit(pkg_part[0], '-', 3)
		if name in mypkg:
			if version == mypkg[name]['version']:
				if build < mypkg[name]['build']:
					print "Trovata build vecchia di " + name + " v " + version
					print "rimuovo " + pkg
					remove(join(dirRepo,pkg))
				elif build > mypkg[name]['build']:
					mypkg[name]['version'] = version
					mypkg[name]['build']   = build
			elif version < mypkg[name]['version']:
				print "Versione vecchia di " + name
				print "rimuovo " + pkg
				remove(join(dirRepo,pkg))
			else:
				mypkg[name]['version'] = version
				mypkg[name]['build']   = build
		else:
			mypkg[name] = { 'version': version, 'build': build }
