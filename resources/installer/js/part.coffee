#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

__selected_target = null
__selected_home = null
__selected_grub = null
__selected_disk = null
__selected_item = null
__selected_line = null
__selected_mode = "simple"
__selected_stage = null

DCore.signal_connect("part_operation", (msg) ->
    if progress_page? and progress_page.display_progress == false
        progress_page.display_progress = true
        progress_page.start_progress()
    progress_page?.update_progress("2%")
    __selected_stage = "extract"
    progress_page?.handle_extract("start")
)

class AddPartDialog extends Dialog
    constructor: (@id, @partid) ->
        super(@id, true, @add_part_cb)
        @add_css_class("DialogCommon")
        @element.style.top = "85px"
        @title_txt.innerText = _("Add partition")
        @fill_type()
        @fill_size()
        @fill_align()
        @fill_fs()
        @fill_mount()
        @fill_tips()
        
    add_part_cb: ->
        @gather_info()
        new_part = add_part(@partid, @n_type, @n_size, @n_align, @n_fs, @n_mp)
        v_part_info[new_part]["mp"] = @n_mp
        Widget.look_up("part_table")?.fill_items()
        Widget.look_up("part_line_maps")?.fill_linemap()
        Widget.look_up(new_part)?.focus()
        Widget.look_up("part")?.fill_bootloader()

    fill_type: ->
        @type = create_element("div", "", @content)
        @type_desc = create_element("span", "AddDesc", @type)
        @type_desc.innerText = _("Type:")
        @type_value = create_element("span", "AddValue", @type)

        @primary_span = create_element("span", "AddValueItem", @type_value)
        @type_primary = create_element("span", "", @primary_span)
        @primary_desc = create_element("span", "", @primary_span)
        @primary_desc.innerText = _("Primary")

        @logical_span = create_element("span", "AddValueItem", @type_value)
        @type_logical = create_element("span", "", @logical_span)
        @logical_desc = create_element("span", "", @logical_span)
        @logical_desc.innerText = _("Logical")

        @type_radio = "primary"
        if not can_add_normal(@partid)
            @primary_span.style.display = "none"
            @type_radio = "logical"
            @type_primary.setAttribute("class", "RadioUnChecked")
            @type_logical.setAttribute("class", "RadioChecked")
        else
            @type_radio = "primary"
            @type_primary.setAttribute("class", "RadioChecked")
            @type_logical.setAttribute("class", "RadioUnchecked")

        if not can_add_logical(@partid)
            @logical_span.style.display = "none"

        @type_primary.addEventListener("click", (e) =>
            @type_radio = "primary"
            @type_primary.setAttribute("class", "RadioChecked")
            @type_logical.setAttribute("class", "RadioUnchecked")
        )
        @type_logical.addEventListener("click", (e) =>
            @type_radio = "logical"
            @type_primary.setAttribute("class", "RadioUnChecked")
            @type_logical.setAttribute("class", "RadioChecked")
        )

    fill_size: ->
        @size = create_element("div", "", @content)
        @size_desc = create_element("span", "AddDesc", @size)
        @size_desc.innerText = _("Size:")
        @max_size_mb = sector_to_mb(v_part_info[@partid]["length"], 512)

        @size_value = create_element("span", "AddValue", @size)
        @size_wrap = create_element("div", "SizeWrap", @size_value)
        @size_input = create_element("input", "", @size_wrap)
        #@size_input.setAttribute("placeholder", @max_size_mb)
        @size_input.setAttribute("value", @max_size_mb)
        @size_input.addEventListener("blur", (e) =>
            parse = parseInt(@size_input.value)
            if isNaN(parse)
                @size_input.value = @max_size_mb 
            else
                if parse < 0
                    @size_input.value = 0 
                else if parse > @max_size_mb
                    @size_input.value = @max_size_mb 
                else
                    @size_input.value = parse 
        )
        @minus_img = create_element("div", "SizeMinus", @size_wrap)
        @minus_img.addEventListener("click", (e) =>
            parse = parseInt(@size_input.value)
            if isNaN(parse)
                @size_input.value = @max_size_mb 
            else
                if parse >= 1
                    @size_input.value = parse - 1 
        )
        @add_img = create_element("div", "SizeAdd", @size_wrap)
        @add_img.addEventListener("click", (e) =>
            parse = parseInt(@size_input.value)
            if isNaN(parse)
                @size_input.value = @max_size_mb 
            else
                if parse <= @max_size_mb - 1 
                    @size_input.value = parse + 1 
        )
        @dw = create_element("div", "SizeDw", @size_wrap)
        @dw.innerText = "MB"
        
    fill_align: ->
        @align = create_element("div", "", @content)
        @align_desc = create_element("span", "AddDesc", @align)
        @align_desc.innerText = _("Align:")
        @align_value = create_element("span", "AddValue", @align)

        @start_span = create_element("span", "AddValueItem", @align_value)
        @align_start = create_element("span", "", @start_span)
        @start_desc = create_element("span", "", @start_span)
        @start_desc.innerText = _("Begin")

        @end_span = create_element("span", "AddValueItem", @align_value)
        @align_end = create_element("span", "", @end_span)
        @end_desc = create_element("span", "", @end_span)
        @end_desc.innerText = _("End")

        @align_radio = "start"
        @align_start.setAttribute("class", "RadioChecked")
        @align_end.setAttribute("class", "RadioUnchecked")

        @align_start.addEventListener("click", (e) =>
            @align_radio = "start"
            @align_start.setAttribute("class", "RadioChecked")
            @align_end.setAttribute("class", "RadioUnchecked")
        )
        @align_end.addEventListener("click", (e) =>
            @align_radio = "end"
            @align_start.setAttribute("class", "RadioUnChecked")
            @align_end.setAttribute("class", "RadioChecked")
        )

    fill_fs: ->
        @fs = create_element("div", "", @content)
        @fs_desc = create_element("span", "AddDesc", @fs)
        @fs_desc.innerText = _("Filesystem:")
        @fs_value = create_element("span", "AddValue", @fs)
        @fs_select = new DropDown("dd_fs_" + @partid, false, @fs_change_cb)
        @fs_value.appendChild(@fs_select.element)
        if DCore.Installer.disk_support_efi(v_part_info[@partid]["disk"])
            @fs_select.set_drop_items(__fs_efi_keys, __fs_efi_values)
        else
            @fs_select.set_drop_items(__fs_keys, __fs_values)
        @fs_select.set_drop_size(130,22)
        @fs_select.set_selected("ext4")
        @fs_select.show_drop()

    fs_change_cb: (part, fs) ->
        if fs in ["efi", "swap", "unused", "fat16", "fat32", "ntfs"]
            Widget.look_up("AddModel").mp.style.display = "none"
        else
            Widget.look_up("AddModel").mp.style.display = "block"

    fill_mount: ->
        @mp = create_element("div", "", @content)
        @mp_desc = create_element("span", "AddDesc", @mp)
        @mp_desc.innerText = _("Mount:")
        @mount_value = create_element("span", "AddValue", @mp)
        @mount_select = new DropDown("dd_mp_" + @partid, true, @mp_change_cb)
        @mount_value.appendChild(@mount_select.element)
        @mount_select.set_drop_items(__mp_keys, __mp_values)
        @mount_select.set_drop_size(130,22)
        @mount_select.set_selected("unused")
        @mount_select.show_drop()

    mp_change_cb: (partid, mp) ->
        if mp.substring(0,1) != "/"
            mp = "unused"
        if mp in get_selected_mp()
            part = get_mp_partition(mp)
            if part? and part != partid
                v_part_info[part]["mp"] = "unused"
                Widget.look_up(part)?.fill_mount()
            else
                echo "error to get mp partition in add dialog"

    fill_tips: ->
        @tips = create_element("div", "", @content)

    gather_info: ->
        if @type_radio == "primary"
            @n_type = "normal"
        else 
            @n_type = "logical"
        if parseInt(@size_input.value) == @max_size_mb
            @n_size = v_part_info[@partid]["length"]
        else
            @n_size = mb_to_sector(parseInt(@size_input.value), 512)
        if not @n_size?
            @tips.innerText = _("Please enter a valid partition size.")
        @n_align = @align_radio
        @n_fs = @fs_select.get_selected()
        @n_mp = @mount_select.get_selected()

class DeletePartDialog extends Dialog
    constructor: (@id,@partid) ->
        super(@id, true, @delete_part_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Delete partition")
        @delete_tips = create_element("div", "", @content)
        @delete_tips.innerText = _("Are you sure you want to delete this partition?")

    delete_part_cb: ->
        remain_part = delete_part(@partid)
        Widget.look_up("part_table")?.fill_items()
        Widget.look_up("part_line_maps")?.fill_linemap()
        Widget.look_up(remain_part)?.focus()
        Widget.look_up("part")?.fill_bootloader()

class UnmountDialog extends Dialog
    constructor: (@id) ->
        super(@id, true, @unmount_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Unmount partition")
        @unmount_tips = create_element("div", "", @content)
        @unmount_tips.innerText = _("Partition is already mounted. Do you want to unmount it?")

    unmount_cb: ->
        echo "unmount all partitions"
        for disk in disks
            for part in m_disk_info[disk]["partitions"]
                try
                    if DCore.Installer.get_partition_mp(part) not in ["/", "/cdrom"]
                        DCore.Installer.unmount_partition(part)
                catch error
                    echo error
        for item in Widget.look_up("part_table")?.partitems
            item.check_busy()

class FormatDialog extends Dialog
    constructor: (@id) ->
        super(@id, true, @format_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Format partition")
        @format_tips = create_element("div", "", @content)
        @format_tips.innerText = _("Are you sure you want to format this partition?")

    format_cb: ->
        echo "format to do install"

class UnavailablePartedDialog extends Dialog
    constructor: (@id) ->
        super(@id, true, @parted_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Do partition")
        @format_tips = create_element("div", "", @content)
        @format_tips.innerText = _("Can't create a partition here")

    parted_cb: ->
        echo "can't create partition here"

class RootDialog extends Dialog
    constructor: (@id) ->
        super(@id, false, @need_root_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Install tips")
        @root_tips = create_element("div", "", @content)
        @root_tips.innerText = _("A root partition is required.")

    need_root_cb: ->
        echo "need mount root to do install"

class UefiDialog extends Dialog
    constructor: (@id) ->
        super(@id, false, @uefi_require_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Install tips")
        @root_tips = create_element("div", "", @content)
        @root_tips.innerText = _("Uefi needs mount a fat32 part to /boot whose size greater than 100M.")

    uefi_require_cb: ->
        echo "uefi require cb"

class UefiBootDialog extends Dialog
    constructor: (@id) ->
        super(@id, false, @uefi_boot_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Install tips")
        @root_tips = create_element("div", "", @content)
        @root_tips.innerText = _("In uefi mode, no needs  to mount a part to /boot manually")

    uefi_boot_cb: ->
        echo "uefi boot cb"

class InstallDialog extends Dialog
    constructor: (@id) ->
        super(@id, true, @confirm_install_cb)
        @add_css_class("DialogCommon")
        @title_txt.innerText = _("Proceed with installation")
        @root_tips = create_element("div", "", @content)
        @fill_install_info()

    confirm_install_cb: ->
        echo "confirm install"
        progress_page = new Progress("progress")
        pc.remove_page(part_page)
        pc.add_page(progress_page)
        setTimeout(->
            if __selected_mode == "simple"
                undo_part_table_info()
                do_simple_partition(__selected_item.id, "part")
            else if __selected_mode == "advance"
                echo "do advance partition"
                do_partition()
        , 300)

    fill_install_info: ->
	    if __selected_mode == "advance"
            target = get_target_part()
        else
            target = __selected_item.id
        path = v_part_info[target]["path"]
	    if v_part_info[target]["type"] == "freespace"
            @root_tips.innerText = _("Linux Deepin will be installed to freespace")
	    else
            @root_tips.innerText = _("Linux Deepin will be installed to ") + path

class PartLineItem extends Widget
    constructor: (@id) ->
        super
        @part = @id[4...16]
        @init_line_item()

    init_line_item: ->
        disk = v_part_info[@part]["disk"]
        @color = v_part_info[@part]["color"]
        @element.style.background = @color
        @element.style.width = Math.round(v_part_info[@part]["length"] / v_disk_info[disk]["length"] * 700)
        @element.style.left = Math.round(v_part_info[@part]["start"] / v_disk_info[disk]["length"] * 700)
        @mask = create_element("div", "Mask", @element)

    focus: ->
        @passive_focus()
        Widget.look_up(@part)?.passive_focus()
    
    passive_focus: ->
        __selected_line?.blur()
        __selected_line = @
        @element.setAttribute("class", "PartLineItemActive")

    blur: ->
        @element.setAttribute("class", "PartLineItem")

    do_click: (e)->
        if __selected_line != @ 
            @focus()

class PartLineMaps extends Widget
    constructor: (@id)->
        super
        @fill_linemap()

    fill_linemap: ->
        @element.innerHTML = ""
        @disk_line = create_element("div", "Line", @element)
        get_disk_fake_length(__selected_disk)
        for part in v_disk_info[__selected_disk]["partitions"]
            if v_part_info[part]["type"] in ["normal", "logical", "freespace"]
                item = new PartLineItem("line"+part)
                @disk_line.appendChild(item.element)

class PartTableItem extends Widget
    constructor: (@id)->
        super
        @lineid = "line" + @id
        @active = false
        @device = create_element("div", "Fat", @element)
        @size = create_element("div", "Thin Size", @element)
        @used = create_element("div", "Thin", @element)
        @fs = create_element("div", "Thin Fs", @element)
        @mount = create_element("div", "Thin Mount", @element)
        @format = create_element("div", "Thin", @element)
        @fill_device()
        @fill_size()
        @fill_used()
        @fill_fs()
        @fill_mount()
        @fill_format()

    fill_device: ->
        @device.innerHTML = ""
        @lock = create_element("span", "Lock", @device)
        @os = create_element("span", "Os", @device)
        @color = create_element("span", "Color", @device)
        @lp = create_element("span", "LabelPath", @device)
        @label = create_element("div", "Label", @lp)
        @path = create_element("div", "Path", @lp)
        @label.addEventListener("mouseover", (e) =>
            @show_detail_label()
        )
        @label.addEventListener("mouseout", (e) =>
            @hide_detail_label()
        )

        if __selected_mode == "advance"
            @fill_device_advance()
        else if __selected_mode == "simple"
            @fill_device_simple()
        txt = @path.innerText
        @path.addEventListener("mouseover", (e) =>
            if os? and os.length > 2
                @path.innerText = DCore.Installer.get_partition_os_desc(@id).split("(")[0].trim()
        )
        @path.addEventListener("mouseout", (e) =>
            @path.innerText = txt
        )

    fill_device_advance: ->
        if v_part_info[@id]["type"] != "freespace"
            @path.innerText = v_part_info[@id]["path"]
        else
            @path.innerText = _("freespace")
        if v_part_info[@id]["label"]? and v_part_info[@id]["label"].length > 0
            if v_part_info[@id]["label"].length > 12
                @label.innerText = v_part_info[@id]["label"].substring(0,12) + "..."
            else
                @label.innerText = v_part_info[@id]["label"]
        else
            @label.style.display = "none"
            @path.setAttribute("style", "margin:10px 0;")
        color_value = v_part_info[@id]["color"]
        @color.style.background = color_value
        @color.style.display = "block"
        os = v_part_info[@id]["os"]
        @update_device_os(os)

    fill_device_simple: ->
        if m_part_info[@id]["type"] != "freespace"
            @path.innerText = m_part_info[@id]["path"]
        else
            @path.innerText = "freespace"
        if m_part_info[@id]["label"]? and m_part_info[@id]["label"].length > 0
            if m_part_info[@id]["label"].length > 12
                @label.innerText = m_part_info[@id]["label"].substring(0,12) + "..."
            else
                @label.innerText = m_part_info[@id]["label"]
        else
            @label.style.display = "none"
            @path.setAttribute("style", "margin:10px 0;")
        @color.style.display = "none"
        os = m_part_info[@id]["os"]
        @update_device_os(os)

    show_detail_label: ->
        if not @label_detail?
            @label_detail = create_element("div", "LabelDetail", @label)
            if __selected_mode == "advance"
                @label_detail.innerText = v_part_info[@id]["label"] 
            else
                @label_detail.innerText = m_part_info[@id]["label"]
        @label_detail.style.display = "block"

    hide_detail_label: ->
        if @label_detail?
            @label_detail.style.display = "none"

    update_device_os: (os) ->
        if os? and os.length > 2
            if os.toLowerCase().indexOf("deepin") != -1
                os_img = "images/deepin.png"
            else if os.toLowerCase().indexOf("linux") != -1
                os_img = "images/linux.png"
            else if os.toLowerCase().indexOf("windows") != -1
                os_img = "images/windows.png"
            else if os.toLowerCase().indexOf("mac") != -1
                os_img = "images/mac.png"
            else
                echo "--------upate device os--------"
                echo os
                os_img = "images/linux.png"
            create_img("", os_img, @os)

    fill_size: ->
        @size.innerHTML = ""
        if __selected_mode == "advance"
            @size.innerText += sector_to_gb(v_part_info[@id]["length"], 512).toFixed(1) + "G"
        else
            @size.innerText += sector_to_gb(m_part_info[@id]["length"], 512).toFixed(1) + "G"

    fill_used: ->
        @used.innerHTML = ""
        if __selected_mode == "advance" and v_part_info[@id]["type"] != "freespace"
            if isNaN(v_part_info[@id]["used"])
                @used.innerText = _("Unknown")
            else
                @used.innerText = (v_part_info[@id]["used"]/1000).toFixed(1) + "G"
        else if __selected_mode == "simple" and m_part_info[@id]["type"] != "freespace"
            if isNaN(m_part_info[@id]["used"])
                @used.innerText = _("Unknown")
            else
                @used.innerText = (m_part_info[@id]["used"]/1000).toFixed(1) + "G"

    update_part_used: ->
        @fill_used()

    fill_format: ->
        @format.innerHTML = ""
        if __selected_mode == "advance"
            @fill_format_advance()
        else
            @format.style.display = "none"

    fill_format_advance: ->
        if not v_part_info[@id]? or v_part_info[@id]["type"] == "freespace"
            return
        @format_img = create_img("Format", "images/check-01.png", @format)
        if not @active
            if v_part_info[@id]["format"]
                @format_img.setAttribute("src", "images/check-02.png")
            else
                @format_img.setAttribute("src", "images/check-01.png")
        else
            if v_part_info[@id]["format"]
                @format_img.setAttribute("src", "images/check-04.png")
            else
                @format_img.setAttribute("src", "images/check-03.png")
        if @is_busy()
            @format_img.setAttribute("src", "images/check-05.png")
        else if @is_format_mandatory()
            @format_img.setAttribute("src", "images/check-06.png")
        @format_img.addEventListener("click", (e) =>
            if @is_busy()
                @format_img.setAttribute("src", "images/check-05.png")
            else if @is_format_mandatory()
                update_part_format(@id, true)
                @format_img.setAttribute("src", "images/check-06.png")
            else
                if v_part_info[@id]["format"]
                    update_part_format(@id, false)
                    @format_img.setAttribute("src", "images/check-03.png")
                else
                    update_part_format(@id, true)
                    @format_img.setAttribute("src", "images/check-04.png")
        )
        @format.style.display = "block"

    is_format_mandatory: ->
        if v_part_info[@id]["type"] == "freespace"
            return false
        if @id not in m_disk_info[v_part_info[@id]["disk"]]["partitions"] or m_part_info[@id]["op"] == "add"
            return true
        if m_part_info[@id]["fs"] != v_part_info[@id]["fs"]
            return true
        return false

    fill_fs: ->
        @fs.innerHTML = ""
        if __selected_mode == "simple" 
            @fill_fs_simple()
        else if __selected_mode == "advance"
            @fill_fs_advance()

    fill_fs_advance: ->
        if not v_part_info[@id]? or v_part_info[@id]["type"] == "freespace"
            return
        if @active
            @fs_select = new DropDown("dd_fs_" + @id, false, @fs_change_cb)
            @fs.appendChild(@fs_select.element)
            if DCore.Installer.disk_support_efi(v_part_info[@id]["disk"])
                @fs_select.set_drop_items(__fs_efi_keys, __fs_efi_values)
            else
                @fs_select.set_drop_items(__fs_keys, __fs_values)
            @fs_select.set_base_background("-webkit-gradient(linear, left top, left bottom, from(rgba(133,133,133,0.6)), color-stop(0.1, rgba(255,255,255,0.6)), to(rgba(255,255,255,0.6)));")
            @fs_select.set_selected(v_part_info[@id]["fs"])
            @fs_select.show_drop()
        else
            @fs_txt = create_element("div", "", @fs)
            if v_part_info[@id]["fs"] != "unused"
                @fs_txt.innerText = v_part_info[@id]["fs"]
            else
                @fs_txt.innerText = ""

    fill_fs_simple: ->
        if m_part_info[@id]? and m_part_info[@id]["type"] != "freespace"
            @fs_txt = create_element("div", "", @fs)
            if m_part_info[@id]["fs"] != "unused"
                @fs_txt.innerText = m_part_info[@id]["fs"]
            else
                @fs_txt.innerText = ""

    fs_change_cb: (part, fs) ->
        if fs in ["efi", "swap", "unused", "fat16", "fat32", "ntfs"]
            Widget.look_up("dd_mp_" + part)?.hide_drop()
        else
            Widget.look_up("dd_mp_"+ part)?.set_drop_items(__mp_keys, __mp_values)
            Widget.look_up("dd_mp_"+ part)?.show_drop()
        update_part_fs(part, fs)

    fill_mount: ->
        @mount.innerHTML = ""
        if __selected_mode != "advance" 
            if @active
                @mount.innerText = _("Install here")
                @mount.setAttribute("style", "text-align:right")
            return
        else
            @fill_mount_advance()

    fill_mount_advance: ->
        if not v_part_info[@id]? or v_part_info[@id]["type"] == "freespace"
            return
        if @active 
            @mount_select = new DropDown("dd_mp_" + @id, true, @mp_change_cb)
            @mount.appendChild(@mount_select.element)
            if v_part_info[@id]["fs"]? 
                @mount_select.set_drop_items(__mp_keys, __mp_values)
            @mount_select.set_base_background("-webkit-gradient(linear, left top, left bottom, from(rgba(133,133,133,0.6)), color-stop(0.1, rgba(255,255,255,0.6)), to(rgba(255,255,255,0.6)));")
            if v_part_info[@id]["mp"].substring(0,1) != "/"
                v_part_info[@id]["mp"] = "unused"
            @mount_select.set_selected(v_part_info[@id]["mp"])
            @mount_select.show_drop()
            if v_part_info[@id]["fs"] in ["efi", "swap", "unused", "fat16", "fat32", "ntfs"]
                @mount_select.hide_drop()
            return
        else
            if v_part_info[@id]["fs"] not in ["efi", "swap", "unused", "fat16", "fat32", "ntfs"]
                @mount_txt = create_element("div", "", @mount)
                if v_part_info[@id]["mp"] == "unused"
                    @mount_txt.innerText = ""
                else
                    @mount_txt.innerText = v_part_info[@id]["mp"]

    mp_change_cb: (partid, mp) ->
        if mp.substring(0,1) != "/"
            mp = "unused"
        if mp in get_selected_mp()
            part = get_mp_partition(mp)
            if part? and part != partid
                v_part_info[part]["mp"] = "unused"
                Widget.look_up(part)?.fill_mount()
            else
                echo "error in get mp partition"
        update_part_mp(partid, mp)

    set_btn_status: ->
        if __selected_mode != "advance"
            return 
        type = v_part_info[@id]["type"]
        add_btn = document.getElementById("part_add")
        delete_btn = document.getElementById("part_delete")

        if type == "freespace"
            if not can_add_normal(@id) and not can_add_logical(@id)
                add_btn.setAttribute("class", "PartAddBtn")
            else
                add_btn.setAttribute("class", "PartAddBtnActive")
            delete_btn.setAttribute("class", "PartDeleteBtn")
        else if type in ["normal", "logical"]
            add_btn.setAttribute("class", "PartAddBtn")
            delete_btn.setAttribute("class", "PartDeleteBtnActive")
        else
            add_btn.setAttribute("class", "PartAddBtn")
            delete_btn.setAttribute("class", "PartDeleteBtn")

        if type != "disk" and v_part_info[@id]["lvm"]
            add_btn.setAttribute("class", "PartAddBtn")
            delete_btn.setAttribute("class", "PartDeleteBtn")

    focus: ->
        @passive_focus()
        Widget.look_up("part_line_maps")?.fill_linemap()
        Widget.look_up(@lineid)?.passive_focus()

    passive_focus: ->
        __selected_item?.blur()
        __selected_item = @
        @element.scrollIntoView()
        @active = true
        @fill_fs()
        @fill_mount()
        @set_btn_status()
        @check_busy()
        @fill_format()
        style = "background:rgba(255,255,3,0.3);"
        style += "font-style:bold;"
        style += "text-shadow:0 1px 2px rgba(0,0,0,0.7);"
        @element.setAttribute("style", style)

    blur: ->
        @active = false
        @fill_fs()
        @fill_mount()
        @fill_format()
        @lock.innerHTML = ""
        @element.setAttribute("style", "")

    is_busy: ->
        if __selected_mode == "advance"
            if v_part_info[@id]["lvm"]? and v_part_info[@id]["lvm"] == true
                return true
        else
            if @id in m_disk_info[v_part_info[@id]["disk"]]["partitions"]
                if m_part_info[@id]["lvm"]? and m_part_info[@id]["lvm"] == true
                    return true
        if @id in m_disk_info[__selected_disk]["partitions"]
            if DCore.Installer.get_partition_busy(@id)
                return true
        return false

    do_click: (e)->
        if __selected_item != @ 
            @focus()

    lock_busy: ->
        @lock.innerHTML = ""
        if __selected_mode == "advance"
            create_img("", "images/lock.png", @lock)
            delete_btn = document.getElementById("part_delete")
            delete_btn.setAttribute("class", "PartDeleteBtn")
            @fs_select?.set_list_enable(false)
            @mount_select?.set_list_enable(false)

    unbusy: ->
        @lock.innerHTML = ""
        if __selected_mode == "advance"
            @fs_select?.set_list_enable(true)
            @mount_select?.set_list_enable(true)

    check_busy: ->
        if @is_busy()
            @lock_busy()
        else
            @unbusy()

class DiskTab extends Widget
    constructor: (@id) ->
        super
        @prev = create_element("div", "Prev", @element)
        @prev.addEventListener("click", (e) =>
            @prev.style.background = "images/arrow_left_press.png"
            @switch_prev()
        )
        @content = create_element("div", "Content", @element)
        @next = create_element("div", "Next", @element)
        @next.addEventListener("click", (e) =>
            @next.style.background = "images/arrow_right_press.png"
            @switch_next()
        )
        if disks.length < 2
            @element.style.display = "none"

    focus_disk: (disk) ->
        index = disks.indexOf(disk) + 1
        if index > 0
            __selected_disk = disk
            size = sector_to_gb(v_disk_info[disk]["length"], 512).toFixed(0)
            @content.innerText = _("Disk") + index  + "  (" + +  size + "GB) "
            Widget.look_up("part_line_maps")?.fill_linemap()
            Widget.look_up("part_table")?.fill_items()
            Widget.look_up(__selected_item?.id)?.focus()

    switch_prev: ->
        index = disks.indexOf(__selected_disk)
        if index > 0
            @focus_disk(disks[index-1])
        
    switch_next: ->
        index = disks.indexOf(__selected_disk)
        if index < disks.length
            @focus_disk(disks[index+1])

class PartTable extends Widget
    constructor: (@id)->
        super
        @header = create_element("div", "PartTableHeader", @element)
        @device_header = create_element("div", "Fat", @header)
        @device_header.innerText = _("Device")
        @size_header = create_element("div", "Size", @header)
        @size_header.innerText = _("Size")
        @used_header = create_element("div", "Thin", @header)
        @used_header.innerText = _("Free Space")
        @fs_header = create_element("div", "Fs", @header)
        @fs_header.innerText = _("Filesystem")
        @info_header = create_element("div", "Info", @header)
        @info_header.innerText = _("Information")
        @mount_header = create_element("div", "Mount", @header)
        @mount_header.innerText = _("Mount point")
        @format_header = create_element("div", "Thin", @header)
        @format_header.innerText = _("Format")

        @items = create_element("div", "PartTableItems", @element)

        @op = create_element("div", "PartOp", @element)
        @part_delete = create_element("div", "PartDeleteBtn", @op)
        @part_delete.setAttribute("id", "part_delete")
        @part_delete.innerText = _("Delete partition")
        @part_delete.addEventListener("click", (e)=>
            echo "handle delete"
            if __in_model
                echo "already had delete part mode dialog"
                return 
            @del_model = new DeletePartDialog("DeleteModel", __selected_item.id)
            document.body.appendChild(@del_model.element)
        )

        @part_add = create_element("div", "PartAddBtn", @op)
        @part_add.setAttribute("id", "part_add")
        @part_add.innerText = _("New partition")
        @part_add.addEventListener("click", (e)=>
            echo "handle add"
            if __in_model
                echo "already had add part mode dialog"
                return 
            @add_model = new AddPartDialog("AddModel", __selected_item.id)
            document.body.appendChild(@add_model.element)
        )

        @update_mode(__selected_mode)

    fill_items: ->
        @items.innerHTML = ""
        @partitems = []
        if __selected_mode == "advance"
            @fill_items_advance()
        else
            @fill_items_simple()
        #if @partitems.length > 0 and @items.scrollHeight > @items.clientHeight
        #    @partitems[@partitems.length - 1].element.setAttribute("class", "PartTableItem PartTableItemLast")

    fill_items_advance: ->
        @info_header.style.display = "none"
        @mount_header.style.display = "block"
        @format_header.style.display = "block"
        @op.style.display = "block"
        disk = __selected_disk
        for part in v_disk_info[disk]["partitions"]
            if v_part_info[part]["type"] in ["normal", "logical", "freespace"]
                item = new PartTableItem(part)
                @items.appendChild(item.element)
                @partitems.push(item)
        @items.setAttribute("style","height:220px")
        @element.setAttribute("style", "height:280px")

    fill_items_simple: ->
        @format_header.style.display = "none"
        @mount_header.style.display = "none"
        @op.style.display = "none"
        @info_header.style.display = "block"
        disk = __selected_disk
        for part in m_disk_info[disk]["partitions"]
            if m_part_info[part]["type"] in ["normal", "logical", "freespace"] and m_part_info[part]["op"] != "add"
                item = new PartTableItem(part)
                @items.appendChild(item.element)
                @partitems.push(item)
        @items.setAttribute("style", "")
        @element.setAttribute("style", "")
        
    update_mode: (mode) ->
        if __selected_item?
            id = __selected_item.id
            __selected_item = null
        else 
            id = null
        @fill_items()
        if id?
            __selected_item = Widget.look_up(id)
            __selected_item?.focus()

class Part extends Page
    constructor: (@id)->
        super
        @titleimg = create_img("", "images/progress_part.png", @titleprogress)

        @helpset = create_element("div", "TitleSet", @title)

        @t_mode = create_element("div", "PartTitleMode", @helpset)
        @t_mode.innerText = _("Expert mode")
        @t_mode.addEventListener("click", (e) =>
            @t_mode.setAttribute("class", "PartTitleMode TitlesetActive")
            @switch_mode()
        )

        @close = create_element("div", "Close", @title)
        @close.addEventListener("click", (e) =>
            @exit_installer()
        )

        @wrap = create_element("div", "", @element)

        @next_btn = create_element("div", "NextStep", @wrap)
        @next_btn.setAttribute("id", "mynextstep")
        @next_input = create_element("input", "InputBtn", @next_btn)
        @next_input.setAttribute("type", "submit")
        @next_input.setAttribute("value", _("Install"))
        @next_btn.addEventListener("mousedown", (e) =>
            @next_input.setAttribute("style", "background:-webkit-gradient(linear, left top, left bottom, from(#D69004), to(#E8C243));color:rgba(0,0,0,1);")
        )
        @next_btn.addEventListener("click", (e) =>
            if __selected_mode == "advance"
                @handle_install_advance()
            else
                @handle_install_simple()
        )

        @init_part_page()

    handle_install_advance: ->
        target = get_target_part()
        if not target?
            @root_model = new RootDialog("RootModel")
            document.body.appendChild(@root_model.element)
            return
        efi_boot = get_efi_boot_part()
        if efi_boot?
            __selected_grub = "uefi"
            if v_part_info[efi_boot]["length"] <= mb_to_sector(100, 512)
                @uefi_model = new UefiDialog("UefiModel")
                document.body.appendChild(@uefi_model.element)
                return
            legacy_boot = get_legacy_boot_part()
            if legacy_boot?
                @uefi_boot_model = new UefiBootDialog("UefiBootModel")
                document.body.appendChild(@uefi_boot_model.element)
                return
        else
            __selected_grub = @grubdropdown?.get_selected()
        if not __selected_grub
            __selected_grub = v_part_info[target]["disk"]
        @install_model = new InstallDialog("InstallModel")
        document.body.appendChild(@install_model.element)

    handle_install_simple: ->
        if __selected_item?
            if m_part_info[__selected_item.id]["type"] == "freespace"
                if not can_add_normal(__selected_item.id) and not can_add_logical(__selected_item.id)
                    @parted_model = new UnavailablePartedDialog("PartedModel")
                    document.body.appendChild(@parted_model.element)
                    return
        __selected_grub = __selected_disk
        @install_model = new InstallDialog("InstallModel")
        document.body.appendChild(@install_model.element)

    init_part_page: ->
        if __selected_mode == null
            __selected_mode = "simple"
        if __selected_disk == null
            __selected_disk = disks[0]

        @disktab = new DiskTab("disk_tab")
        @wrap.appendChild(@disktab.element)

        @linemap = new PartLineMaps("part_line_maps")
        @wrap.appendChild(@linemap.element)

        @table = new PartTable("part_table")
        @wrap.appendChild(@table.element)

        @part_grub = create_element("div", "PartGrub", @wrap)
        @grub_loader = create_element("div", "PartGrubLoader", @part_grub)
        @grub_loader.innerText = _("Boot loader")
        @grub_select = create_element("div", "PartGrubSelect", @part_grub)
        @fill_bootloader()

        @switch_mode_simple()
        recommand = get_recommand_target()
        if recommand?
            @disktab.focus_disk(m_part_info[recommand]["disk"])
            Widget.look_up(recommand)?.focus()
        else
            @disktab.focus_disk(__selected_disk)
        if  __selected_item?
            @next_btn.setAttribute("style", "pointer-events:auto")
            @next_input.setAttribute("style", "background:-webkit-gradient(linear, left top, left bottom, from(rgba(240,242,82,1)), to(rgba(217,181,24,1)));")

    fill_bootloader: ->
        efi_boot = get_efi_boot_part()
        if efi_boot?
            @part_grub.style.display = "none"
            return
        keys = []
        values = []
        for disk in disks
            text = v_disk_info[disk]["path"] + "\t" + v_disk_info[disk]["model"] + "\t" + sector_to_gb(v_disk_info[disk]["length"], 512).toFixed(0) + "GB"
            keys.push(disk)
            values.push(text)
            for part in v_disk_info[disk]["partitions"]
                if v_part_info[part]["type"] in ["normal", "logical"]
                    keys.push(part)
                    values.push(v_part_info[part]["path"])
        if @grub_dropdown?
            @grub_dropdown?.destroy()
            @grub_dropdown = null
        @grub_dropdown = new DropDown("dd_grub", false, null)
        @grub_select.appendChild(@grub_dropdown.element)
        @grub_dropdown.set_drop_items(keys, values)
        @grub_dropdown.set_drop_size(700 - @grub_loader.offsetWidth - 10, 20)
        @grub_dropdown.show_drop()

    switch_mode: ->
        if __selected_mode != "advance"
            @switch_mode_advance()
        else
            @switch_mode_simple()

    switch_mode_advance: ->
        __selected_mode = "advance"
        if check_has_mount()
            @unmount_model = new UnmountDialog("UnmountModel")
            document.body.appendChild(@unmount_model.element)
        @linemap.element.setAttribute("style", "display:block")
        @part_grub.setAttribute("style", "display:block")
        efi_boot = get_efi_boot_part()
        if efi_boot?
            @part_grub.style.display = "none"
        else
            @part_grub.style.display = "block"
            @grub_dropdown.set_drop_size(700 - @grub_loader.offsetWidth - 10, 20)
            @grub_dropdown.show_drop()
        @table.update_mode(__selected_mode)
        @t_mode.innerText = _("Simple mode")

    switch_mode_simple: ->
        __selected_mode = "simple"
        @add_model?.hide_dialog()
        @delete_model?.hide_dialog()
        @unmount_model?.hide_dialog()
        @linemap.element.setAttribute("style", "display:none")
        @part_grub.style.display = "none"
        @table.update_mode(__selected_mode)
        @t_mode.innerText = _("Expert mode") 
