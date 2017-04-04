# Notational Velocity for Atom

*`notational-velocity` package is renamed to `nvatom` package due to a fatal bug. For more info, refer [migration section](#migration).*

[![Build Status][3]][4]

[Notational Velocity][1] is an application that stores and retrieves notes.

![Preview][5]

This Atom package implements the some key features from this amazing app:

- Modeless operation
- Mouseless interaction
- Incremental Search
- Interlinks

Integrated with Atom, we have several advantages:

- __Use Atom's Features__ - Such as Syntax Highlighting and Tree View.
- __Use Other Packages__ - Such as Markdown Preview and Minimap.
- __Multi-OS__ - You can use it in OSX, Linux and Windows.

We do believe Notational Velocity is the precursor of the famous note-taking app Evernote. Advantages over Evernote are:

- __Open Source__
- __No Rich Text__ - Instead, we strongly recommend to use [Markdown][2].
- __Sync Whereever You Want__ - You can save notes locally, in Dropbox, or in Google Drive.

## Settings

To configure your note directory, set `nvatom.directory`:

* Open your `~/.atom/config.cson` file from the menu: *Atom > Open Your Config*
* Append the following lines:

    ```cson
      'nvatom':
        directory: '/path/to/your/notes'
    ```

The first line should be indented by one step from `*` at the top. If you've
kept the default indentation of two spaces, the block above should paste in
properly.

Double-quotes also work.

## Key Bindings

- `alt-cmd-l`: Toggles the search view.
- `alt-cmd-o`: Jumps to the referred note when the cursor is on the interlink in the form of [[double-bracketed interlink]].

You can also override `cmd-l` if you want to keep your muscle memory from Notational Velocity and nvALT. Just edit your keymap (Atom menu -> Open Your Keymap) and add the following lines:

```cson
'atom-text-editor':
  'cmd-l': 'unset!'
'atom-workspace':
  'cmd-l': 'nvatom:toggle'
```

To set Windows and Linux key binds you can add the following lines to your keymap:

```cson
'atom-workspace':
  'alt-ctrl-l': 'nvatom:toggle'
'atom-workspace atom-text-editor':
  'alt-ctrl-o': 'nvatom:openInterlink'
```

## Migration

v0.1.0 under published package name `notational-velocity` had a fatal bug that sets the default value of its note directory under package directory. In that case, all notes are deleted once the user updates the package, since package directory is overwritten when the user. For more information, refer [#25][6].

To resolve this problem, we renamed our package name to `nvatom`. Users who have the old `notational-velocity` need to **install `nvatom` package first**, activate the package to automatically migrate the existing notes, and then delete `notational-velocity` package.

Since keymaps overlap with `notational-velocity`, follow the menu *Packages > nvAtom > Toggle* to activate this package.

## References

- [Notational Velocity](http://notational.net/)
- [nvALT](http://brettterpstra.com/projects/nvalt/)
- [Markdown](http://daringfireball.net/projects/markdown/)
- [CommonMark](http://commonmark.org/)
- [Evernote](https://evernote.com/)
- [Simplenote](http://simplenote.com/)

[1]: http://notational.net/
[2]: http://daringfireball.net/projects/markdown/syntax
[3]: https://travis-ci.org/seongjaelee/nvatom.svg?branch=master
[4]: https://travis-ci.org/seongjaelee/nvatom
[5]: https://cloud.githubusercontent.com/assets/948301/7246990/2e2b4c6e-e7b9-11e4-93b0-57954e011e81.gif
[6]: https://github.com/seongjaelee/nvatom/issues/25
