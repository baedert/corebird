

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
  g_clear_pointer (&self->menu, gtk_widget_unparent);

  G_OBJECT_CLASS (cb_badge_radio_button_parent_class)->dispose (object);
}

static void
cb_badge_radio_button_measure (GtkWidget      *widget,
                               GtkOrientation  orientation,
                               int             for_size,
                               int            *minimum,
                               int            *natural,
                               int            *minimum_baseline,
                               int            *natural_baseline)
{
  CbBadgeRadioButton *self = (CbBadgeRadioButton *)widget;
  int min, nat;

  gtk_widget_measure (self->button, orientation, for_size,
                      &min, &nat, NULL, NULL);

  *minimum = min;
  *natural = nat;

  gtk_widget_measure (self->badge, orientation, for_size,
                      &min, &nat, NULL, NULL);

  *minimum = MAX (*minimum, min);
  *natural = MAX (*natural, nat);
}

static void
cb_badge_radio_button_size_allocate (GtkWidget *widget,
                                     int        width,
                                     int        height,
                                     int        baseline)
{
  CbBadgeRadioButton *self = (CbBadgeRadioButton *)widget;

  gtk_widget_size_allocate (self->button, &(GtkAllocation) { 0, 0, width, height }, -1);
  gtk_widget_size_allocate (self->badge,  &(GtkAllocation) { 0, 0, width, height }, -1);

  if (self->menu)
    gtk_popover_present (GTK_POPOVER (self->menu));
}

static void
cb_badge_radio_button_class_init (CbBadgeRadioButtonClass *class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (class);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (class);

  object_class->dispose = cb_badge_radio_button_dispose;
  object_class->get_property = cb_badge_radio_button_get_property;
  object_class->set_property = cb_badge_radio_button_set_property;

  widget_class->measure = cb_badge_radio_button_measure;
  widget_class->size_allocate = cb_badge_radio_button_size_allocate;

  gtk_widget_class_set_css_name (widget_class, "badgebutton");
}

static void
cb_badge_radio_button_init (CbBadgeRadioButton *self)
{
}

static void
create_ui (CbBadgeRadioButton *self,
           const char         *icon_name,
           const char         *text,
           GtkToggleButton    *group)
{
  g_assert (self->button);

  gtk_toggle_button_set_group (GTK_TOGGLE_BUTTON (self->button), group);
  gtk_button_set_icon_name (GTK_BUTTON (self->button), icon_name);
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
cb_badge_radio_button_new (GtkToggleButton *group,
                           const char      *icon_name,
                           const char      *text)
{
  CbBadgeRadioButton *self = (CbBadgeRadioButton *)g_object_new (CB_TYPE_BADGE_RADIO_BUTTON,
                                                                 NULL);

  self->button = gtk_toggle_button_new ();
  create_ui (self, icon_name, text, group);

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

static void
gesture_pressed_cb (GtkGestureClick    *gesture,
                    guint               n_press,
                    double              x,
                    double              y,
                    CbBadgeRadioButton *self)
{
  gtk_popover_popup (GTK_POPOVER (self->menu));
}

void
cb_badge_radio_button_set_menu (CbBadgeRadioButton *self,
                                GMenu              *menu)
{
  GtkGesture *gesture;

  g_assert (CB_IS_BADGE_RADIO_BUTTON (self));

  g_assert (!self->menu);

  self->menu = gtk_popover_menu_new_from_model (G_MENU_MODEL (menu));
  gtk_widget_set_parent (self->menu, GTK_WIDGET (self));
  gesture = gtk_gesture_click_new ();
  gtk_gesture_single_set_touch_only (GTK_GESTURE_SINGLE (gesture), FALSE);
  gtk_gesture_single_set_exclusive (GTK_GESTURE_SINGLE (gesture), TRUE);
  gtk_gesture_single_set_button (GTK_GESTURE_SINGLE (gesture), GDK_BUTTON_SECONDARY);

  g_signal_connect (gesture, "pressed", G_CALLBACK (gesture_pressed_cb), self);
  gtk_widget_add_controller (GTK_WIDGET (self->button), GTK_EVENT_CONTROLLER (gesture));
}
