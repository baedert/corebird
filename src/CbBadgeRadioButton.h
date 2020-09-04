

#pragma once
#include <gtk/gtk.h>

struct _CbBadgeRadioButton
{
  GtkWidget parent_instance;

  GtkWidget *button;
  GtkWidget *badge;

  GtkWidget *menu;
};

typedef struct _CbBadgeRadioButton CbBadgeRadioButton;

#define CB_TYPE_BADGE_RADIO_BUTTON cb_badge_radio_button_get_type ()
G_DECLARE_FINAL_TYPE (CbBadgeRadioButton, cb_badge_radio_button, CB, BADGE_RADIO_BUTTON, GtkWidget);

CbBadgeRadioButton *            cb_badge_radio_button_new            (GtkToggleButton    *group,
                                                                      const char         *icon_name,
                                                                      const char         *text);
GtkWidget *                     cb_badge_radio_button_get_button     (CbBadgeRadioButton *self);

void                            cb_badge_radio_button_set_show_badge (CbBadgeRadioButton *self,
                                                                      gboolean            value);
gboolean                        cb_badge_radio_button_get_show_badge (CbBadgeRadioButton *self);

void                            cb_badge_radio_button_set_active     (CbBadgeRadioButton *self,
                                                                      gboolean            value);
gboolean                        cb_badge_radio_button_get_active     (CbBadgeRadioButton *self);

void                            cb_badge_radio_button_set_menu       (CbBadgeRadioButton *self,
                                                                      GMenu              *menu);
