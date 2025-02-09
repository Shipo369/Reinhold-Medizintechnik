import React, { useRef, useState } from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import Heading from '@tiptap/extension-heading';
import HorizontalRule from '@tiptap/extension-horizontal-rule';
import Placeholder from '@tiptap/extension-placeholder';
import TextAlign from '@tiptap/extension-text-align';
import Underline from '@tiptap/extension-underline';
import Image from '@tiptap/extension-image';
import { Bold, Italic, Underline as UnderlineIcon, List, AlignLeft, AlignCenter, AlignRight, Minus, Undo, Redo, Type, Image as ImageIcon, Loader2 } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface EditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  title: string;
  onTitleChange: (title: string) => void;
}

const CustomDocument = Document.extend({
  content: 'heading block*',
});

const CustomImage = Image.extend({
  addAttributes() {
    return {
      src: {
        default: null,
        parseHTML: element => element.getAttribute('src'),
        renderHTML: attributes => ({
          src: attributes.src
        })
      },
      alignment: {
        default: 'left',
        parseHTML: element => element.getAttribute('data-alignment'),
        renderHTML: attributes => ({
          'data-alignment': attributes.alignment,
          class: `max-w-full h-auto rounded-lg my-4 align-${attributes.alignment}`
        })
      }
    };
  }
});

export function Editor({ value, onChange, placeholder, title, onTitleChange }: EditorProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploading, setIsUploading] = useState(false);

  const editor = useEditor({
    extensions: [
      CustomDocument,
      StarterKit.configure({
        document: false,
      }),
      Placeholder.configure({
        placeholder: placeholder || 'Beginnen Sie mit der Eingabe...',
      }),
      HorizontalRule.configure({
        HTMLAttributes: {
          class: 'slide-divider',
        },
      }),
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      Underline,
      CustomImage
    ],
    content: value,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  if (!editor) {
    return null;
  }

  const handleImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Check file type
    if (!file.type.startsWith('image/')) {
      alert('Bitte wählen Sie eine Bilddatei aus.');
      return;
    }

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('Die Datei ist zu groß. Maximale Größe ist 5MB.');
      return;
    }

    try {
      setIsUploading(true);

      // Upload to Supabase Storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `presentation-images/${fileName}`;

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('presentations')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('presentations')
        .getPublicUrl(filePath);

      // Insert image into editor
      editor.chain().focus().setImage({ 
        src: publicUrl,
        alignment: 'left'
      }).run();
    } catch (err) {
      console.error('Error uploading image:', err);
      alert('Fehler beim Hochladen des Bildes. Bitte versuchen Sie es erneut.');
    } finally {
      setIsUploading(false);
      // Reset input
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const setImageAlignment = (alignment: 'left' | 'center' | 'right') => {
    const { state, dispatch } = editor.view;
    const { from, to } = state.selection;

    state.doc.nodesBetween(from, to, (node, pos) => {
      if (node.type.name === 'image') {
        const transaction = state.tr.setNodeMarkup(pos, null, {
          ...node.attrs,
          alignment
        });
        dispatch(transaction);
        return false;
      }
      return true;
    });
  };

  return (
    <div className="bg-white rounded-lg shadow-lg border border-gray-200">
      {/* Title Input */}
      <div className="p-4 border-b border-gray-200">
        <input
          type="text"
          value={title}
          onChange={(e) => onTitleChange(e.target.value)}
          placeholder="Präsentationstitel eingeben..."
          className="w-full text-xl font-semibold px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

      {/* Toolbar */}
      <div className="border-b border-gray-200 p-2 flex flex-wrap gap-2 sticky top-0 bg-white z-10">
        <button
          onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
          className={`p-2 rounded hover:bg-gray-100 ${
            editor.isActive('heading', { level: 1 }) ? 'bg-gray-100' : ''
          }`}
        >
          <Type className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().toggleBold().run()}
          className={`p-2 rounded hover:bg-gray-100 ${
            editor.isActive('bold') ? 'bg-gray-100' : ''
          }`}
        >
          <Bold className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().toggleItalic().run()}
          className={`p-2 rounded hover:bg-gray-100 ${
            editor.isActive('italic') ? 'bg-gray-100' : ''
          }`}
        >
          <Italic className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().toggleUnderline().run()}
          className={`p-2 rounded hover:bg-gray-100 ${
            editor.isActive('underline') ? 'bg-gray-100' : ''
          }`}
        >
          <UnderlineIcon className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().toggleBulletList().run()}
          className={`p-2 rounded hover:bg-gray-100 ${
            editor.isActive('bulletList') ? 'bg-gray-100' : ''
          }`}
        >
          <List className="h-5 w-5" />
        </button>

        <div className="flex space-x-1">
          <button
            onClick={() => setImageAlignment('left')}
            className={`p-2 rounded hover:bg-gray-100 ${
              editor.isActive('image', { alignment: 'left' }) ? 'bg-gray-100' : ''
            }`}
            title="Linksbündig"
          >
            <AlignLeft className="h-5 w-5" />
          </button>
          <button
            onClick={() => setImageAlignment('center')}
            className={`p-2 rounded hover:bg-gray-100 ${
              editor.isActive('image', { alignment: 'center' }) ? 'bg-gray-100' : ''
            }`}
            title="Zentriert"
          >
            <AlignCenter className="h-5 w-5" />
          </button>
          <button
            onClick={() => setImageAlignment('right')}
            className={`p-2 rounded hover:bg-gray-100 ${
              editor.isActive('image', { alignment: 'right' }) ? 'bg-gray-100' : ''
            }`}
            title="Rechtsbündig"
          >
            <AlignRight className="h-5 w-5" />
          </button>
        </div>

        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={isUploading}
          className="p-2 rounded hover:bg-gray-100 disabled:opacity-50 relative"
          title="Bild einfügen"
        >
          {isUploading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            <ImageIcon className="h-5 w-5" />
          )}
          <input
            type="file"
            ref={fileInputRef}
            onChange={handleImageUpload}
            accept="image/*"
            className="hidden"
            disabled={isUploading}
          />
        </button>

        <button
          onClick={() => editor.chain().focus().setHorizontalRule().run()}
          className="p-2 rounded hover:bg-gray-100"
          title="Neue Folie"
        >
          <Minus className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().undo().run()}
          disabled={!editor.can().undo()}
          className="p-2 rounded hover:bg-gray-100 disabled:opacity-50"
        >
          <Undo className="h-5 w-5" />
        </button>

        <button
          onClick={() => editor.chain().focus().redo().run()}
          disabled={!editor.can().redo()}
          className="p-2 rounded hover:bg-gray-100 disabled:opacity-50"
        >
          <Redo className="h-5 w-5" />
        </button>
      </div>

      <EditorContent editor={editor} className="prose max-w-none p-4" />
    </div>
  );
}