

#include "CbBadgeRadioButton.h"

G_DEFINE_TYPE (CbBadgeRadioButton, cb_badge_radio_button, GTK_TYPE_WIDGET);

enum {
  PROP_0 = 0,
  PROP_ACTIVE,
};

static void
cb_badge_radio_button_get_property (GObject    *object,
                                    guint       property_id,
                                    GValue     *value,
                                    GParamSpec *pspec)
{
  switch (property_id)
    {
    case PROP_ACTIVE:
      g_value_set_boolean (value,
                           cb_badge_radio_button_get_active ((CbBadgeRadioButton *)object));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
cb_badge_radio_button_set_property (GObject      *object,
                                    guint         property_id,
                                    const GValue *value,
                                    GParamSpec   *pspec)
{
  switch (property_id)
    {
    case PROP_ACTIVE:
      cb_badge_radio_button_set_active ((CbBadgeRadioButton *)object,
                                        g_value_get_boolean (value));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
cb_badge_radio_button_dispose (GObject *object)
{
  CbBadgeRadioButton *self = (CbBadgeRadioButton *)object;

  g_clear_pointer (&self->button, gtk_widget_unparent);
  g_clear_pointer (&self->badge, gtk_widget_unparent);

  G_OBJECT_CLASS (cb_badge_radio_button_parent_class)->dispose (object);
}

static void
cb_badge_radio_button_class_init (CbBadgeRadioButtonClass *class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (class);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (class);

  object_class->dispose = cb_badge_radio_button_dispose;
  object_class->get_property = cb_badge_radio_button_get_property;
  object_class->set_property = cb_badge_radio_button_set_property;

  gtk_widget_class_set_css_name (widget_class, "badgebutton");
  gtk_widget_class_set_layout_manager_type (widget_class, GTK_TYPE_BIN_LAYOUT);
}

static void
cb_badge_radio_button_init (CbBadgeRadioButton *self)
{
}


static void
create_ui (CbBadgeRadioButton *self,
           const char         *icon_name,
           const char         *text)
{
  g_assert (self->button);

  gtk_check_button_set_draw_indicator (GTK_CHECK_BUTTON (self->button), FALSE);
  gtk_button_set_icon_name (GTK_BUTTON (self->button), icon_name);
  if (text && text[0] != '\0')
    {
      AtkObject *accessible;

      gtk_widget_set_tooltip_text (GTK_WIDGET (self), text);

      accessible = gtk_widget_get_accessible (GTK_WIDGET (self));
      atk_object_set_name (accessible, text);
    }
  gtk_widget_set_parent (self->button, (GtkWidget *)self);

  self->badge = g_object_new (GTK_TYPE_FRAME, /* TODO: Because we can't instantiate GtkWidget */
                              "css-name", "badge",
                              NULL);
  gtk_widget_set_halign (self->badge, GTK_ALIGN_END);
  gtk_widget_set_valign (self->badge, GTK_ALIGN_START);
  gtk_widget_set_child_visible (self->badge, FALSE);
  gtk_widget_set_parent (self->badge, (GtkWidget *)self);
}

CbBadgeRadioButton *
cb_badge_radio_button_new (GtkRadioButton *group,
                           const char     *icon_name,
                           const char     *text)
{
  CbBadgeRadioButton *self = (CbBadgeRadioButton *)g_object_new (CB_TYPE_BADGE_RADIO_BUTTON,
                                                                 NULL);

  self->button = gtk_radio_button_new_from_widget (group);
  create_ui (self, icon_name, text);

  return self;
}

GtkWidget *
cb_badge_radio_button_get_button (CbBadgeRadioButton *self)
{
  return self->button;
}

void
cb_badge_radio_button_set_show_badge (CbBadgeRadioButton *self,
                                      gboolean            value)
{
  if (value != cb_badge_radio_button_get_show_badge (self))
    {
      gtk_widget_set_child_visible (self->badge, value);

      // TODO: notify
    }
}

gboolean
cb_badge_radio_button_get_show_badge (CbBadgeRadioButton *self)
{
  return gtk_widget_get_child_visible (self->badge);
}

void
cb_badge_radio_button_set_active (CbBadgeRadioButton *self,
                                  gboolean            value)
{
  if (value != cb_badge_radio_button_get_active (self))
    {
      gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->button), value);

      // notify
    }
}

gboolean
cb_badge_radio_button_get_active (CbBadgeRadioButton *self)
{
  return gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (self->button));
}

