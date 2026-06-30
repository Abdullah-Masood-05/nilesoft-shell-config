//==============================================================
//  My Tools  —  Nilesoft Shell add-on
//--------------------------------------------------------------
//  HOW TO USE
//   1. Put this file in the SAME folder as shell.nss
//      (usually C:\Program Files\Nilesoft Shell).
//   2. Inside the  shell { ... }  block of shell.nss add:
//          import 'my-tools.nss'
//      (or just paste the menu blocks below straight into shell.nss)
//   3. Hold CTRL and right-click anywhere to reload. No reboot.
//      Errors, if any, are logged to shell.log in the same folder.
//
//  ICONS — every icon is set with the  image=  property.
//   * Nilesoft's own glyphs:   image=\uE1E7        (browse nilesoft.org/glyphs)
//     with color/size:         image.glyph(0xE1E7, #5b8def, 12)
//   * Windows icon fonts:      image.mdl(\uE8C8)   "Segoe MDL2 Assets"
//                              image.fluent(\uE8C8) "Segoe Fluent Icons" (Win11)
//   * System DLL icons:        image('imageres.dll', -1024)  /  image('shell32.dll', 4)
//   * A file / svg / color:    image='C:\icon.ico'  image.svgf('C:\i.svg')  image=#5b8def
//   * An app's real icon:      image='C:\Windows\System32\cmd.exe'
//
//  The icons below are safe placeholders: real named Segoe glyphs where
//  I was certain, color chips elsewhere (with a note on which glyph to
//  grab). Swap any image= for a \uEXXX from the gallery to match your menu.
//==============================================================


//---------------------------- COPY ----------------------------
// Suitable icon for "copy path" = a clipboard glyph.  E8C8 = Copy.
menu(title='Copy' type='file|dir|back' image=icon.copy)
{
	// Multi-select: copy every selected path, one per line
	item(vis=@(sel.count > 1)
		title='Copy @sel.count paths'
		cmd=command.copy(sel(false, "\n")))

	// Full path
	item(mode='single' title=sel.path
		cmd=command.copy(sel.path))

	// Quoted path  ("C:\...")  — paste-ready for terminals
	item(mode='single' title=sel.path.quote
		cmd=command.copy(sel.path.quote))

	separator

	// Name with extension
	item(mode='single' type='file|dir' title=sel.name
		cmd=command.copy(sel.name))

	// Name without extension
	item(mode='single' type='file' title=sel.title
		cmd=command.copy(sel.title))

	// Extension only
	item(mode='single' type='file' title=sel.file.ext
		cmd=command.copy(sel.file.ext))

	separator

	// Parent folder path
	item(mode='single' title=sel.parent
		cmd=command.copy(sel.parent))
}


//----------------------- NEW FILE -----------------------------
menu(title='New file' type='back|dir' image=icon.new_file)     // try a new-document glyph
{
	item(title='Text file (.txt)' dir=sel.curdir window=hidden
		cmd='cmd.exe' args='/c type nul > "new file.txt"')

	item(title='Markdown (.md)'   dir=sel.curdir window=hidden
		cmd='cmd.exe' args='/c type nul > "new file.md"')

	item(title='Python (.py)'     dir=sel.curdir window=hidden
		cmd='cmd.exe' args='/c type nul > "new script.py"')
}


//----------------------- SYSTEM / POWER -----------------------
menu(title='System' type='back|desktop' image=icon.settings)  // E713 = Settings gear
{
	// Restart File Explorer
	item(title='Restart Explorer'
		cmd='cmd.exe' window=hidden
		args='/c taskkill /f /im explorer.exe & start explorer.exe'
		image=image.mdl(\uE72C))       // E72C = Refresh

	// Empty Recycle Bin
	item(title='Empty Recycle Bin'
		cmd='powershell.exe' window=hidden
		args='-NoProfile -Command Clear-RecycleBin -Force -ErrorAction SilentlyContinue'
		image=image.mdl(\uE74D))       // E74D = Delete

	// Flush DNS cache (admin)
	item(title='Flush DNS' admin=true
		cmd='cmd.exe' window=hidden args='/c ipconfig /flushdns'
		image=#20bf6b)                 // try a globe glyph

	// God Mode — every Control Panel task in one window
	item(title='God Mode'
		cmd='explorer.exe'
		args='shell:::{ED7BA470-8E54-465E-825C-99712043E01C}'
		image=#9b59b6)

	separator

	item(title='Lock'      cmd='rundll32.exe' args='user32.dll,LockWorkStation'        image=image.mdl(\uE72E))
	item(title='Sleep'     cmd='rundll32.exe' args='powrprof.dll,SetSuspendState 0,1,0' image=#34495e)
	item(title='Sign out'  cmd='shutdown.exe' args='/l'                                 image=#e67e22)
	item(title='Restart'   cmd='shutdown.exe' args='/r /t 0'                            image=#e74c3c)
	item(title='Shut down' cmd='shutdown.exe' args='/s /t 0'                            image=#c0392b)
}
