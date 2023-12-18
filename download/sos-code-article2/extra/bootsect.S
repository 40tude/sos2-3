
/*
 * @(#) $Id: bootsect.S,v 1.6 2004/06/18 07:43:51 d2 Exp $
 * Description : Bootsecteur en syntaxe AT&T
 * Auteurs : Thomas Petazzoni & Fabrice Gautier & Emmanuel Marty
 *	     Jerome Petazzoni & Bernard Cassagne & coffeeman
 *	     David Decotigny
 * Bug reports to kos-misc@enix.org
 */

/*
 * But global de ce bootsecteur :
 *
 *		- Initialiser la becane
 *		- Charger le kernel
 *		- Passer en mode protege
 *		- Executer le kernel
 *
 * Taille restante : Je vous rappelle qu'un bootsecteur ne peut faire
 * qu'au maximum 512 octets dont 2 octets obligatoires 0xAA55.  Sur
 * les 510 octets reellement utilisables, il reste 3 octets dispo (60
 * si on decide d'enlever le BPB un jour) !!!
 *
 * thomas_petazzoni :  - detection des codes d'erreurs de chargement
 * David_Decotigny  :  - Passage en GNU as
 * David_Decotigny  :  - Chargement du noyau au-dela du 1er Mega (taille
 *                       max = 0x9e000 octets = 632ko), pour avoir le
 *                       meme noyau sous grub et avec le bootsecteur
 */

 /*
  * Sequence d'operations :
  * - Le BIOS charge le bootsect en 0x7c00 (BOOT_ADRESS). On choisit
  *   la representation 0x7c0:0000 pour que le .org 0 reste valide
  * - Le bootsect se deplace de lui-meme en 0x9f000 (COPY_ADRESS). On
  *   choisit la representation 0x9f00:0000 pour que le .org 0 reste
  *   valide
  * - Le bootsect verifie que le processeur est du type 386+
  * - Il charge le noyau depuis la disquette en memoire a partir de
  *   0x1000 (LOAD_ADRESS). Le noyau peut au max tenir sur
  *   SECTORS_TO_LOAD secteurs
  * - Il passe en pmode flat (apres ouverture a20)
  * - Il recopie le noyau (situe en LOAD_ADRESS) vers son adresse
  *   finale (FINAL_ADDRESS = 2Mo). La recopie se fait sur tout l'espace
  *   LOAD_ADRESS ---> COPY_ADRESS, c'est a dire sur 0x9e000 octets =
  *   632ko. Le noyau peut donc au max faire 632ko. Le nombre max de
  *   secteurs de disquette qu'on peut charger est donc 1264
  */


/* La taille de la pile */
#define BOOT_STACK_SIZE	        0x4000

	.file	"bootsect.S"

	/* Tout est place dans une seule section */
	.section ".bootsect"

	/* L'essentiel du bootsector (sauf les 1eres instructions)
	   sont a un offset 0. On fait en sorte que le compilo soit
	   d'accord la-dessus. Quand on a des adresse realm exotiques
	   (0x7c00, 0x9f000, ...), on s'arrange toujours pour avoir un
	   offset de 0 => on choisira le segment adapte (0x7c0,
	   0x9f00, ...). Il ne faut pas oublier le ld -Ttext 0 */
	.org 0

	/* Pour que gas genere du 16bits, afin que ca marche en realm */
	.code16

#define SECTORS_TO_LOAD 128 /* 64 ko */ /* MAX=1264 */

/*
 * Parametres de la disquette. Comme c'est chiant de faire une
 * procedure de detection auto, et que ca prend de la place, on fait
 * ca "a la main". Par exemple, une DD 720 Ko a 9 secteurs/piste, une
 * 1.44 Mo a 18 secteurs/pistes
 */
#define CYLS    80
#define HEADS   1
#define SECTS   18

#define BOOT_ADRESS 0x07C00  	       /* Adresse de demarrage (lineaire) */
#define BOOT_SEG (BOOT_ADRESS>>4)      /* Segment de Boot */
#define BOOT_SIZE 512		       /* Taille bu bootsecteur */
#define COPY_ADRESS 0x9F000  	       /* La ou on va copier le
					  bootsecteur (lineaire) */
#define COPY_SEG (COPY_ADRESS>>4)      /* Segment de la ou on va
					  copier le bootsecteur */
#define LOAD_ADRESS 0x01000  	       /* 1er chargement du systeme */
#define LOAD_SEG (LOAD_ADRESS>>4)      /* Segment du 1er chargement du */
#define MAX_KERN_LEN COPY_ADRESS-LOAD_ADRESS /* Taille noyau maxi */

/* IMPORTANT : Cette valeur DOIT etre identique a l'adresse presente
	       dans sos.lds ! */
#define FINAL_ADDRESS 0x200000         /* Adresse finale (physique de 0 a 4G)
	                                  ou est charge le noyau */

#define OP16 .byte 0x66 ;
#define OP32 .byte 0x66 ;

/*
 * Procedure qui vide le buffer clavier.
 */
#define WAITKB     \
  1:               ;\
    .word 0xeb     ;\
    .word 0xeb     ;\
    inb $0x64, %al ;\
    andb $0x2, %al ;\
    jnz 1b

	/* Le point d'entree dans le bootsect */
.globl _bsect
_bsect:

	/*
	 * La portion qui suit est situee a un offset 0x7c00 en
	 * memoire. Attention donc aux references memoire dans cette
	 * partie. On choisit de rester en offset 0 (.org 0), mais on
         * charge correctement les segments a 0x7c0.
         */

	movw $BOOT_SEG, %ax /* le bootsecteur est a 0x7C00 en lineaire */
	movw %ax, %ds      /* on le copie a l'adresse COPY_ADRESS */
	xorw %si, %si      /* comme cette adresse est la plus haute de la mem */
	xorw %di, %di      /* on pourra charger un kernel + gros */
	movw $(BOOT_SIZE>>1), %cx
	movw $COPY_SEG, %ax
	movw %ax, %es
	cld
	rep ; movsw
			
	/* on continue a executer le bootsecteur, mais maintenant a
           partir de 0x9F000, qu'on represente sous la forme
           0x9f00:offset */
	ljmp $COPY_SEG, $here

	/*
	 * A partir de maintenant, on est a un offset 0 en memoire
         * (segment 0x9f00), conformement a ce que veut le compilo.
	 */
here:
	movw %ax, %ds

	/* Petite pile temporaire (1k - 3.84k en RAM ; les adresses 0-1k
	   correspondent au vecteur d'interruptions). */
	movw %ax, %ss
    	movw $(LOAD_ADRESS - 0x10), %sp
        
	/* Efface l'ecran */
	movb $0x0, %ah
	movb $0x3, %al
	int 	$0x10

	/* Affiche les messages d'attente */
	movw $loadkern, %si
	call message
	movw $check, %si
	call message

check386:
	/*
	 * la attention, plus complexe : on teste si le proc est un
	 * 386+ pour cela, on va essayer de modifier les bits 12 ? 14
	 * du registre E-flag si la modification reste, alors le proc
	 * est un 386+, sinon, c'est =< 286
	 *
	 * Merci a Emmanuel Marty pour la compatibilite avec les 386
	 * "pre-jurassique"
	 */

	pushf /* on sauvegarde le E-Flag */
	movb $0x70, %ah
	pushw %ax
	popf
	pushf
	popw %ax
	orb %ah, %ah
	je no386  /* si la modif n'est pas valable, alors on saute a
                     no386 */
	popf      /* on les restaure ? la fin ... */

	/* Message de confirmation de 386+ et d'attente */
        movw $found386, %si
	call message
	movw $loading, %si
	call message

/* Copie du noyau disquette => RAM a partir de 0x1000
   L'adresse de destination est définie par es:0, où es vaut
   initialement 0x100 (ie correspond alors à l'adresse 256*16, soit 4
   ko). Chaque itération incrémente ce registre es de 32, ce qui
   correspond à un bond de 32*16 en mémoire, soit la taille d'un
   secteur. De cette façon, puisqu'on joue sur les segments plutôt que
   sur les offsets, la taille du noyau n'est pas limitée à 64 ko. Elle
   est limitée par contre à la taille de la mémoire disponible sous
   les 1Mo, \ie 640 ko (0x9f000 - 0x1000).  */
copyKernel:
	/* Chargement du noyau en LOAD_SEG:0 */
	/* 3 iterateurs :
		- load_size : le nbre de secteurs a charger
		- cl : le secteur ou on en est pour le
		  cylindre en cours (<= SECTS)
		- dh : la tete en cours (0/1)
	*/
	movb $0, %dl
	movw $LOAD_SEG, %ax
	movw %ax, %es

	xorw %bx, %bx
	xorw %dx, %dx
	movw $1, %cx  	 /*  premier secteur */

.nextsector:         	 /* prochain secteur */
	incb %cl    	 /* en incrementant CL */
	cmpb $SECTS, %cl /* si CL =< SECTS (=nbre de secteurs/pistes)
			    alors on charge */
	jbe .sector
	movb $1, %cl     /* sinon on revient au secteur 1 */
	incb %dh         /* mais sur l'autre tete */
	cmpb $1, %dh     /* on recompare, si DH =< 1 */
	je .sector	 /* on charge */
	movb $0, %dh     /* sinon on repasse a la tete 0 */
	incb %ch         /* mais on change de cylindre */

.sector:
	pushw %es
	movw $0x0201, %ax /* service 0x2, chargement 0x1 seecteur */
	int $0x13          /* Go ! */
	jc halt           /* erreur */
	popw %ax
	addw $32, %ax     /* on a charge un secteur, donc on doit
			     charger 512 bytes plus loin */
	movw %ax, %es     /* on avance donc le segment du buffer de
                             32bytes, ie 1 secteur en RAM (car 32*16=512) */

	movw $(0x0E*256+'.'), %ax /* affiche un point */
	int $0x10

	decw (load_size)     /* et on repart pour le prochain secteur
                             tant qu'on n'a pas fini ! */
	jnz .nextsector

after:
	movw $0x03f2, %dx
	inb  %dx, %al  /* stoppe le moteur */
        andb $0x0f, %al
        outb %al, %dx

        cli               /* on interdit les interruptions */

fincopie:        
        pushw %cs
        popw  %ds

	/* on ouvre la porte A20 */
    	WAITKB           /* on vide le buffer */
	movb $0xd1, %al /* on met a jour le port */
	outb %al, $0x64
	WAITKB
	movb $0xdf, %al /* bit 2 = ouverture/fermeture */
	outb %al, $0x60

	/*
	 * init gdt
	 */
InitGDT:
	/* Préparation du flat mode */
        lgdt gdtr

GoPMode:
	/* Passage en mode protégé */
	movl %cr0, %eax
	orb  $1, %al /* set PE bit to 1 */
	movl %eax, %cr0

	/* we are not yet in Pmode jump 'in' pmode clearing prefetch
	 * queue and loading a new selector */
	movw $0x10, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs

/*
 * Code 32 bits ============================================================
 */
	.code32	

JumpToHere32: /* Se deplace a l'endroit actuel, en passant en 32bits
	         et en utilisant la gdt, et vide la prefetch queue */
	.byte 0x66 /* Prefixe 32bits : en realite, jusqu'au jmp, on est
                      encore en 16 bits */
	ljmp $0x8, $(COPY_ADRESS+(Here32))
Here32:
	/* Et voila : On est en 32 bits vrai */

MoveKernelToFinalAddr: /* Deplace le noyau (en LOAD_ADDRESS) vers sa
	                  destination finale (FINAL_ADDRESS) */
	movl $0x10, %eax
	movl %eax, %ds   /* Seg Src  = DSeg */
	movl %eax, %es   /* Sed Dest = DSeg */
	cld
	movl $LOAD_ADRESS, %esi    /* On commence la copie au debut du noyau */
	movl $FINAL_ADDRESS, %edi  /* On copie vers cette adresse */
	movl $MAX_KERN_LEN, %ecx   /* Taille recopie */
	shrl $2, %ecx
	rep
	movsl

LaunchKernel:
	/* Met en place une pile au niveau du symbole "stack" */
	movl %eax, %ss
	movl $(stack + BOOT_STACK_SIZE), %ebp
	movl %ebp, %esp
	
	/* Saut vers le noyau. La GDT est en place (flat mode), les
 	 * selecteurs aussi, a20 est ouverte, et les interruptions sont
	 * cli + pas de idt. Le PIC n'est pas programme */
	ljmp $0x8, $sos_main

/*
 * Utilities ============================================================
 */
	.code16

message:
        lodsb             /* charge ds:si dans al et incremente si */
	orb %al, %al      /* si al = 0 */
	jz 1f
	movb $0x0e, %ah   /* service 0Eh (affichage d'un caractere) */
	movw $0x0007, %bx /* Parametres : blanc sur fond noir */
        int $0x10          /* Appel de l'interruption 10h */
        jmp message       /* On repart au début ... */
     1: ret               /* si la chaine est finie alors on retourne
                             dans la fonction appelante */

halt:
	pushw %cs
	popw %es
	movw $haltmsg, %si
        call message
	cli
     1:	jmp 1b
        ret

no386:
	movw $need386, %si
	call message
	call halt

	/*
	 * GDT
	 */

gdt:
gdtr:
NULL_Desc:
	.word (EndGDT)-(gdt)-1 /* Taille GDT */
	.long (gdt)+COPY_ADRESS
unused:	
	.word   0

CS_Desc: /* 0x8 */
	.word	0xFFFF, 0
	.byte	0, 0x9B, 0xCF, 0

DS_Desc: /* 0x10 */
	.word	0xFFFF, 0
	.byte	0, 0x93, 0xCF, 0

EndGDT:

     /* quelques messages */

loadkern:  .string      "-= S O S =- : The Simple Operating System \r\n"
check:     .string      "Checking for a 386+ processor... "
found386:  .string      " [OK]\r\n"
need386:   .string      " [FAILED]\r\n"
diskerror: .string	"Disk Error\r\n"
loading:   .string	"Loading... "
haltmsg:   .string	"System Halted\r\n"

/*** Les code/données du boot secteur se terminent ICI. le marqueur de
 * fin (aa55) est ajouté automatiquement par le script ld
 * sos_bsect.lds ***/

/* La pile de 16k qu'on utilise au niveau de LaunchKernel se trouve
   declaree avec le noyau, dans sa section ".bss", cad HORS du boot
   secteur ! (sinon ca depasserait 512B, forcément). On aurait pu la
   définir directement dans le sos_bsect.lds, ou dans un fichier .c
   auxiliaire pour plus de clarté */
.comm	stack, BOOT_STACK_SIZE
