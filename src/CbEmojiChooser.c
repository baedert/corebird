/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * This is basically GtkEmojiChooser from GTK+ but with less features.
 */

#include "CbEmojiChooser.h"
#include <string.h>

#define EMOJI_PER_ROW 7

/* From 2017-10-18 */
#define EMOJI_DATA_CHECKSUM "2ad33472d280d83737884a0e60a9236793653111"

enum {
  EMOJI_PICKED,
  LAST_SIGNAL
};

static int signals[LAST_SIGNAL];

G_DEFINE_TYPE (CbEmojiChooser, cb_emoji_chooser, GTK_TYPE_BOX);

static void
scroll_to_section (GtkButton *button,
                   gpointer   data)
{
  EmojiSection *section = data;
  CbEmojiChooser *chooser;
  GtkAdjustment *adj;
  GtkAllocation alloc = { 0, 0, 0, 0 };
  double page_increment, value;
  gboolean dummy;

  chooser = CB_EMOJI_CHOOSER (gtk_widget_get_ancestor (GTK_WIDGET (button), CB_TYPE_EMOJI_CHOOSER));

  adj = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (chooser->scrolled_window));
  if (section->heading)
    gtk_widget_get_allocation (section->heading, &alloc);
  page_increment = gtk_adjustment_get_page_increment (adj);
  value = gtk_adjustment_get_value (adj);
  gtk_adjustment_set_page_increment (adj, alloc.y - value);
  g_signal_emit_by_name (chooser->scrolled_window, "scroll-child", GTK_SCROLL_PAGE_FORWARD, FALSE, &dummy);
  gtk_adjustment_set_page_increment (adj, page_increment);
}

static void
add_emoji (GtkWidget    *box,
           gboolean      prepend,
           GVariant     *item,
           gunichar      modifier);

#define MAX_RECENT (EMOJI_PER_ROW * 3)

static void
populate_recent_section (CbEmojiChooser *chooser)
{
  GVariant *variant;
  GVariant *item;
  GVariantIter iter;

  variant = g_settings_get_value (chooser->settings, "recent-emoji");
  g_variant_iter_init (&iter, variant);
  while ((item = g_variant_iter_next_value (&iter)))
    {
      GVariant *emoji_data;
      gunichar modifier;

      emoji_data = g_variant_get_child_value (item, 0);
      g_variant_get_child (item, 1, "u", &modifier);
      add_emoji (chooser->recent.box, FALSE, emoji_data, modifier);
      g_variant_unref (emoji_data);
      g_variant_unref (item);
    }
  g_variant_unref (variant);
}

static void
add_recent_item (CbEmojiChooser *chooser,
                 GVariant        *item,
                 gunichar         modifier)
{
  GList *children, *l;
  int i;
  GVariantBuilder builder;

  g_variant_ref (item);

  g_variant_builder_init (&builder, G_VARIANT_TYPE ("a((auss)u)"));
  g_variant_builder_add (&builder, "(@(auss)u)", item, modifier);

  children = gtk_container_get_children (GTK_CONTAINER (chooser->recent.box));
  for (l = children, i = 1; l; l = l->next, i++)
    {
      GVariant *item2 = g_object_get_data (G_OBJECT (l->data), "emoji-data");
      gunichar modifier2 = GPOINTER_TO_UINT (g_object_get_data (G_OBJECT (l->data), "modifier"));

      if (modifier == modifier2 && g_variant_equal (item, item2))
        {
          gtk_widget_destroy (GTK_WIDGET (l->data));
          i--;
          continue;
        }
      if (i >= MAX_RECENT)
        {
          gtk_widget_destroy (GTK_WIDGET (l->data));
          continue;
        }

      g_variant_builder_add (&builder, "(@(auss)u)", item2, modifier2);
    }
  g_list_free (children);

  add_emoji (chooser->recent.box, TRUE, item, modifier);

  g_settings_set_value (chooser->settings, "recent-emoji", g_variant_builder_end (&builder));

  g_variant_unref (item);
}

static void
emoji_activated (GtkFlowBox      *box,
                 GtkFlowBoxChild *child,
                 gpointer         data)
{
  CbEmojiChooser *chooser = data;
  char *text;
  GtkWidget *label;
  GVariant *item;
  gunichar modifier;

  label = gtk_bin_get_child (GTK_BIN (child));
  text = g_strdup (gtk_label_get_label (GTK_LABEL (label)));

  item = (GVariant*) g_object_get_data (G_OBJECT (child), "emoji-data");
  modifier = (gunichar) GPOINTER_TO_UINT (g_object_get_data (G_OBJECT (child), "modifier"));
  add_recent_item (chooser, item, modifier);

  g_signal_emit (data, signals[EMOJI_PICKED], 0, text);
  g_free (text);
}

static void
add_emoji (GtkWidget    *box,
           gboolean      prepend,
           GVariant     *item,
           gunichar      modifier)
{
  GtkWidget *child;
  GtkWidget *label;
  PangoAttrList *attrs;
  GVariant *codes;
  char text[64];
  char *p = text;
  guint i;

  codes = g_variant_get_child_value (item, 0);
  for (i = 0; i < g_variant_n_children (codes); i++)
    {
      gunichar code;

      g_variant_get_child (codes, i, "u", &code);
      if (code == 0)
        code = modifier;
      if (code != 0)
        p += g_unichar_to_utf8 (code, p);
    }
  g_variant_unref (codes);
  p[0] = 0;

  label = gtk_label_new (text);
  attrs = pango_attr_list_new ();
  pango_attr_list_insert (attrs, pango_attr_scale_new (PANGO_SCALE_X_LARGE));
  gtk_label_set_attributes (GTK_LABEL (label), attrs);
  pango_attr_list_unref (attrs);

  child = gtk_flow_box_child_new ();
  gtk_style_context_add_class (gtk_widget_get_style_context (child), "emoji");
  g_object_set_data_full (G_OBJECT (child), "emoji-data",
                          g_variant_ref (item),
                          (GDestroyNotify)g_variant_unref);
  if (modifier != 0)
    g_object_set_data (G_OBJECT (child), "modifier", GUINT_TO_POINTER (modifier));

  gtk_container_add (GTK_CONTAINER (child), label);
  gtk_flow_box_insert (GTK_FLOW_BOX (box), child, prepend ? 0 : -1);
}

typedef struct {
  CbEmojiChooser *chooser;
  GVariantIter iter;
  GtkWidget *box; /* We need to keep this around so subsequent
                     emojis get added to the rigth section */
} PopulateData;

static gboolean
populate_one_emoji (gpointer user_data)
{
  const guint N = 4; /* Kinda-sorta sweetspot on my system... */
  PopulateData *data = user_data;
  GVariant *item;
  const char *name;
  guint i = 0;


  while (i < N)
    {
      item = g_variant_iter_next_value (&data->iter);

      if (item == NULL)
        {
          data->chooser->populate_idle_id = 0;
          return G_SOURCE_REMOVE;
        }

      g_variant_get_child (item, 1, "&s", &name);

      if (strcmp (name, data->chooser->body.first) == 0)
        data->box = data->chooser->body.box;
      else if (strcmp (name, data->chooser->nature.first) == 0)
        data->box = data->chooser->nature.box;
      else if (strcmp (name, data->chooser->food.first) == 0)
        data->box = data->chooser->food.box;
      else if (strcmp (name, data->chooser->travel.first) == 0)
        data->box = data->chooser->travel.box;
      else if (strcmp (name, data->chooser->activities.first) == 0)
        data->box = data->chooser->activities.box;
      else if (strcmp (name, data->chooser->objects.first) == 0)
        data->box = data->chooser->objects.box;
      else if (strcmp (name, data->chooser->symbols.first) == 0)
        data->box = data->chooser->symbols.box;
      else if (strcmp (name, data->chooser->flags.first) == 0)
        data->box = data->chooser->flags.box;

      add_emoji (data->box, FALSE, item, 0);
      g_variant_unref (item);

      i ++;
    }

  return G_SOURCE_CONTINUE;
}

static void
populate_emoji_chooser (CbEmojiChooser *self)
{
  PopulateData *data = g_malloc0 (sizeof (PopulateData));

  data->chooser = self;

  g_variant_iter_init (&data->iter, self->data);
  data->box = self->people.box;

  self->populate_idle_id = g_idle_add_full (G_PRIORITY_DEFAULT_IDLE,
                                            populate_one_emoji,
                                            data,
                                            g_free);
}

static void
adj_value_changed (GtkAdjustment *adj,
                   gpointer       data)
{
  CbEmojiChooser *chooser = data;
  double value = gtk_adjustment_get_value (adj);
  EmojiSection const *sections[] = {
    &chooser->recent,
    &chooser->people,
    &chooser->body,
    &chooser->nature,
    &chooser->food,
    &chooser->travel,
    &chooser->activities,
    &chooser->objects,
    &chooser->symbols,
    &chooser->flags,
  };
  EmojiSection const *select_section = sections[0];
  gsize i;

  /* Figure out which section the current scroll position is within */
  for (i = 0; i < G_N_ELEMENTS (sections); ++i)
    {
      EmojiSection const *section = sections[i];
      GtkAllocation alloc;

      if (section->heading)
        gtk_widget_get_allocation (section->heading, &alloc);
      else
        gtk_widget_get_allocation (section->box, &alloc);

      if (value < alloc.y)
        break;

      select_section = section;
    }

  /* Un/Check the section buttons accordingly */
  for (i = 0; i < G_N_ELEMENTS (sections); ++i)
    {
      EmojiSection const *section = sections[i];

      if (section == select_section)
        gtk_widget_set_state_flags (section->button, GTK_STATE_FLAG_CHECKED, FALSE);
      else
        gtk_widget_unset_state_flags (section->button, GTK_STATE_FLAG_CHECKED);
    }
}

static gboolean
filter_func (GtkFlowBoxChild *child,
             gpointer         data)
{
  EmojiSection *section = data;
  CbEmojiChooser *chooser;
  GVariant *emoji_data;
  const char *text;
  const char *name;
  gboolean res;

  res = TRUE;

  chooser = CB_EMOJI_CHOOSER (gtk_widget_get_ancestor (GTK_WIDGET (child), CB_TYPE_EMOJI_CHOOSER));
  text = gtk_entry_get_text (GTK_ENTRY (chooser->search_entry));
  emoji_data = (GVariant *) g_object_get_data (G_OBJECT (child), "emoji-data");

  if (text[0] == 0)
    goto out;

  if (!emoji_data)
    goto out;

  g_variant_get_child (emoji_data, 1, "&s", &name);
  res = strstr (name, text) != NULL;

out:
  if (res)
    section->empty = FALSE;

  return res;
}

static void
invalidate_section (EmojiSection *section)
{
  section->empty = TRUE;
  gtk_flow_box_invalidate_filter (GTK_FLOW_BOX (section->box));
}

static void
update_headings (CbEmojiChooser *chooser)
{
  gtk_widget_set_visible (chooser->people.heading, !chooser->people.empty);
  gtk_widget_set_visible (chooser->people.box, !chooser->people.empty);
  gtk_widget_set_visible (chooser->body.heading, !chooser->body.empty);
  gtk_widget_set_visible (chooser->body.box, !chooser->body.empty);
  gtk_widget_set_visible (chooser->nature.heading, !chooser->nature.empty);
  gtk_widget_set_visible (chooser->nature.box, !chooser->nature.empty);
  gtk_widget_set_visible (chooser->food.heading, !chooser->food.empty);
  gtk_widget_set_visible (chooser->food.box, !chooser->food.empty);
  gtk_widget_set_visible (chooser->travel.heading, !chooser->travel.empty);
  gtk_widget_set_visible (chooser->travel.box, !chooser->travel.empty);
  gtk_widget_set_visible (chooser->activities.heading, !chooser->activities.empty);
  gtk_widget_set_visible (chooser->activities.box, !chooser->activities.empty);
  gtk_widget_set_visible (chooser->objects.heading, !chooser->objects.empty);
  gtk_widget_set_visible (chooser->objects.box, !chooser->objects.empty);
  gtk_widget_set_visible (chooser->symbols.heading, !chooser->symbols.empty);
  gtk_widget_set_visible (chooser->symbols.box, !chooser->symbols.empty);
  gtk_widget_set_visible (chooser->flags.heading, !chooser->flags.empty);
  gtk_widget_set_visible (chooser->flags.box, !chooser->flags.empty);

  if (chooser->recent.empty && chooser->people.empty &&
      chooser->body.empty && chooser->nature.empty &&
      chooser->food.empty && chooser->travel.empty &&
      chooser->activities.empty && chooser->objects.empty &&
      chooser->symbols.empty && chooser->flags.empty)
    gtk_stack_set_visible_child_name (GTK_STACK (chooser->stack), "empty");
  else
    gtk_stack_set_visible_child_name (GTK_STACK (chooser->stack), "list");
}

static void
search_changed (GtkEntry *entry,
                gpointer  data)
{
  CbEmojiChooser *chooser = data;

  invalidate_section (&chooser->recent);
  invalidate_section (&chooser->people);
  invalidate_section (&chooser->body);
  invalidate_section (&chooser->nature);
  invalidate_section (&chooser->food);
  invalidate_section (&chooser->travel);
  invalidate_section (&chooser->activities);
  invalidate_section (&chooser->objects);
  invalidate_section (&chooser->symbols);
  invalidate_section (&chooser->flags);

  update_headings (chooser);
}

static void
setup_section (CbEmojiChooser *chooser,
               EmojiSection   *section,
               const char     *first,
               gunichar        label)
{
  char text[14];
  char *p;
  GtkAdjustment *adj;

  section->first = first;

  p = text;
  p += g_unichar_to_utf8 (label, p);
  p += g_unichar_to_utf8 (0xfe0e, p);
  p[0] = 0;
  gtk_button_set_label (GTK_BUTTON (section->button), text);

  adj = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (chooser->scrolled_window));

  gtk_container_set_focus_vadjustment (GTK_CONTAINER (section->box), adj);
  gtk_flow_box_set_filter_func (GTK_FLOW_BOX (section->box), filter_func, section, NULL);
  g_signal_connect (section->button, "clicked", G_CALLBACK (scroll_to_section), section);
}

static void
cb_emoji_chooser_finalize (GObject *object)
{
  CbEmojiChooser *self = CB_EMOJI_CHOOSER (object);

  if (self->data != NULL)
    g_variant_unref (self->data);

  g_clear_object (&self->settings);

  if (self->populate_idle_id != 0)
    g_source_remove (self->populate_idle_id);

  G_OBJECT_CLASS (cb_emoji_chooser_parent_class)->finalize (object);
}

static void
cb_emoji_chooser_init (CbEmojiChooser *self)
{
  GtkAdjustment *adj;


  gtk_widget_init_template (GTK_WIDGET (self));

  adj = gtk_scrolled_window_get_vadjustment (GTK_SCROLLED_WINDOW (self->scrolled_window));
  g_signal_connect (adj, "value-changed", G_CALLBACK (adj_value_changed), self);

  setup_section (self, &self->recent, NULL, 0x1f557);
  setup_section (self, &self->people, "grinning face", 0x1f642);
  setup_section (self, &self->body, "selfie", 0x1f44d);
  setup_section (self, &self->nature, "monkey face", 0x1f337);
  setup_section (self, &self->food, "grapes", 0x1f374);
  setup_section (self, &self->travel, "globe showing Europe-Africa", 0x2708);
  setup_section (self, &self->activities, "jack-o-lantern", 0x1f3c3);
  setup_section (self, &self->objects, "muted speaker", 0x1f514);
  setup_section (self, &self->symbols, "ATM sign", 0x2764);
  setup_section (self, &self->flags, "chequered flag", 0x1f3f4);


  /* We scroll to the top on show, so check the right button for the 1st time */
  gtk_widget_set_state_flags (self->recent.button, GTK_STATE_FLAG_CHECKED, FALSE);
}

static void
cb_emoji_chooser_class_init (CbEmojiChooserClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_emoji_chooser_finalize;

  signals[EMOJI_PICKED] = g_signal_new ("emoji-picked",
                                        G_OBJECT_CLASS_TYPE (object_class),
                                        G_SIGNAL_RUN_LAST,
                                        0,
                                        NULL, NULL,
                                        NULL,
                                        G_TYPE_NONE, 1, G_TYPE_STRING|G_SIGNAL_TYPE_STATIC_SCOPE);

  gtk_widget_class_set_template_from_resource (widget_class, "/org/baedert/corebird/ui/cb-emoji-chooser.ui");

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, search_entry);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, stack);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, scrolled_window);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, recent.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, recent.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, people.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, people.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, people.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, body.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, body.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, body.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, nature.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, nature.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, nature.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, food.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, food.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, food.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, travel.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, travel.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, travel.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, activities.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, activities.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, activities.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, objects.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, objects.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, objects.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, symbols.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, symbols.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, symbols.button);

  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, flags.box);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, flags.heading);
  gtk_widget_class_bind_template_child (widget_class, CbEmojiChooser, flags.button);

  gtk_widget_class_bind_template_callback (widget_class, emoji_activated);
  gtk_widget_class_bind_template_callback (widget_class, search_changed);
}

GtkWidget *
cb_emoji_chooser_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_EMOJI_CHOOSER, NULL));
}

void
cb_emoji_chooser_populate (CbEmojiChooser *self)
{
  if (self->populated)
    return;

  self->populated = TRUE;
  populate_emoji_chooser (self);
}

gboolean
cb_emoji_chooser_try_init (CbEmojiChooser *self)
{
  GBytes *bytes;
  char *checksum;
  GVariant *settings_test;
  gboolean recent_in_correct_format = FALSE;
  gboolean correct_checksum = FALSE;
  GSettingsSchemaSource *schema_source;
  GSettingsSchema *schema;

  schema_source = g_settings_schema_source_get_default ();
  schema = g_settings_schema_source_lookup (schema_source, "org.gtk.Settings.EmojiChooser", TRUE);

  if (schema == NULL)
    {
      g_message ("Emoji chooser: Schema not found");
      return FALSE;
    }

  g_settings_schema_unref (schema);
  schema = NULL;

  self->settings = g_settings_new ("org.gtk.Settings.EmojiChooser");
  settings_test = g_settings_get_value (self->settings, "recent-emoji");

  recent_in_correct_format = g_variant_is_of_type (settings_test, G_VARIANT_TYPE ("a((auss)u)"));
  g_variant_unref (settings_test);

  if (!recent_in_correct_format)
    {
      g_message ("Emoji chooser: Recent variant in wrong format");
      return FALSE;
    }

  bytes = g_resources_lookup_data ("/org/gtk/libgtk/emoji/emoji.data", 0, NULL);

  if (bytes == NULL)
    {
      g_message ("Emoji chooser: resources not available");
      return FALSE;
    }

  checksum = g_compute_checksum_for_bytes (G_CHECKSUM_SHA1, bytes);

  correct_checksum = strcmp (checksum, EMOJI_DATA_CHECKSUM) == 0;
  if (!correct_checksum)
    {
      g_message ("Emoji chooser: checksum mismatch. %s != %s", checksum, EMOJI_DATA_CHECKSUM);
      g_free (checksum);
      g_bytes_unref (bytes);
      return FALSE;
    }
  g_free (checksum);

  self->data = g_variant_ref_sink (g_variant_new_from_bytes (G_VARIANT_TYPE ("a(auss)"),
                                                             bytes, TRUE));
  g_bytes_unref (bytes);

  populate_recent_section (self);

  return TRUE;
}
