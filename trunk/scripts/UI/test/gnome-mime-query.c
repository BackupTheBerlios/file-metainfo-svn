#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

//#include <gnome.h>
#include <libintl.h>
#include <stdio.h>
#include <string.h>
#include <glib.h>
#include <libgnomevfs/gnome-vfs.h>


int print_error (GnomeVFSResult result, const char *uri_string);
int print_icon (const char *icon_name);
int print_applications (GnomeVFSMimeApplication *appdata);

int
main (int argc, char *argv[])
{ 
  GList *alist; 
  GList *is;
  char *iconFileName;
  char *mime_type;
  g_print("argc: %d\n",argc);	
  if (argc < 2){
	  g_print("You must specify a mime-type\n");
	  return 1;
  }
  g_print("argv[1]: %s,%d\n",argv[1],strlen(argv[1])*sizeof(char));	

#ifdef ENABLE_NLS
  bindtextdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
  textdomain (GETTEXT_PACKAGE);
#endif

  /*gnome_program_init (PACKAGE, VERSION, LIBGNOMEUI_MODULE,
                      argc, argv,
                      GNOME_PARAM_APP_DATADIR, PACKAGE_DATA_DIR,
                      NULL);
*/

  /* remember to initialize GnomeVFS! */
  if (!gnome_vfs_init ()) {
    printf ("Could not initialize GnomeVFS\n");
    return 1;
  }
  printf ("GnomeVFS Initialized\n");
  mime_type=(char *)g_malloc(strlen(argv[1])*sizeof(char));
  strcpy(mime_type,argv[1]);
  printf ("Mime-type is %s\n",mime_type);
  /* get list of associated applications */
  alist=gnome_vfs_mime_get_all_applications(mime_type);
  for (is = alist; is != NULL; is = is->next){
	  print_applications(is->data);
  }

  g_list_foreach(alist,(GFunc)g_free,NULL);
  g_list_free(alist);

  /* get mime-type icon */
  iconFileName=gnome_vfs_mime_get_icon (mime_type);
  print_icon(iconFileName);
}
 
int
print_error (GnomeVFSResult result, const char *uri_string)
{
  const char *error_string;
  /* get the string corresponding to this GnomeVFSResult value */
  error_string = gnome_vfs_result_to_string (result);
  printf ("Error %s occured opening location %s\n", error_string, uri_string);
  return 1;
}


int
print_applications(GnomeVFSMimeApplication *appdata){
	g_print ("%s\n",appdata->name);
	return 0;
};

int
print_icon(const char *icon_name){
	g_print ("%s\n",(char *)icon_name);
	return 0;
};
