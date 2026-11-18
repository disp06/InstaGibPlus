class IGPlus_CrosshairSettingsContent extends UMenuPageWindow;

var IGPlus_CrosshairSettingsDialog ParentDialog;
var ClientSettings Settings;
var bool bUpdatingControls;

var IGPlus_Button Btn_AddLayer;
var IGPlus_Button Btn_RemLayer;

var IGPlus_CrosshairLayersListBox LB_Layers;
var UWindowList LastSelected;

// Presets: the list, + for a new one, - to delete the picked one, and its name.
var IGPlus_Button Btn_AddPreset;
var IGPlus_Button Btn_RemPreset;
var IGPlus_Label Lbl_Presets;
var localized string PresetsText;
var IGPlus_CrosshairPresetsListBox LB_Presets;
var IGPlus_EditControl Edit_PresetName;
var localized string PresetNameText;

var IGPlus_Label Lbl_Scale;
var localized string ScaleText;
var IGPlus_BtnUp Btn_ScaleUp;
var IGPlus_BtnDown Btn_ScaleDown;
var IGPlus_BtnLeft Btn_ScaleLeft;
var IGPlus_BtnRight Btn_ScaleRight;

var IGPlus_Label Lbl_Offset;
var localized string OffsetText;
var IGPlus_BtnUp Btn_OffsetUp;
var IGPlus_BtnDown Btn_OffsetDown;
var IGPlus_BtnLeft Btn_OffsetLeft;
var IGPlus_BtnRight Btn_OffsetRight;

var IGPlus_EditControl Edit_Texture;
var localized string TextureText;

var IGPlus_EditControl Edit_OffsetX;
var localized string OffsetXText;
var IGPlus_EditControl Edit_OffsetY;
var localized string OffsetYText;

var IGPlus_EditControl Edit_ScaleX;
var localized string ScaleXText;
var IGPlus_EditControl Edit_ScaleY;
var localized string ScaleYText;

var IGPlus_EditControl Edit_ColorRed;
var localized string ColorRedText;
var IGPlus_EditControl Edit_ColorGreen;
var localized string ColorGreenText;
var IGPlus_EditControl Edit_ColorBlue;
var localized string ColorBlueText;
var IGPlus_EditControl Edit_ColorAlpha;
var localized string ColorAlphaText;

var IGPlus_ComboBox Cmb_Style;
var localized string StyleText;
var localized string StyleNormal;
var localized string StyleMasked;
var localized string StyleTranslucent;
var localized string StyleModulated;

var IGPlus_Checkbox Chk_Smooth;
var localized string SmoothText;

var UWindowSmallCloseButton Btn_Close;
var UwindowSmallButton Btn_Save;

// Share codes: the layers in the list as one line of text, through the
// clipboard. IGCH1:<layer>;<layer>;... with each layer
// Texture,OffsetX,OffsetY,ScaleX,ScaleY,R,G,B,A,Style,Smooth.
// A pasted code replaces the layers in the list; Save keeps them.
var IGPlus_Button Btn_CopyCode;
var IGPlus_Button Btn_PasteCode;
var localized string CopyCodeText;
var localized string PasteCodeText;
var localized string CodeCopiedText;
var localized string CodePastedText;
var localized string CodeBadText;
const IGPLUS_CH_CODE_PREFIX = "IGCH1:";

function CopyCrosshairLayers() {
	local bbPlayer P;
	local bbCHSpectator Spec;
	local int i;
	local IGPlus_CrosshairLayersListItem Item;

	P = bbPlayer(GetPlayerOwner());
	if (P == none) {
		Spec = bbCHSpectator(GetPlayerOwner());
		if (Spec == none)
			return;
		Settings = Spec.Settings;
	} else {
		Settings = P.Settings;
	}
	if (Settings == none)
		return;

	for (i = 0; i < 10; ++i) {
		if (Settings.GetCrosshairLayer(i).bUse == false)
			continue;

		Item = IGPlus_CrosshairLayersListItem(LB_Layers.Items.CreateItem(LB_Layers.ListClass));
		if (Item == none)
			continue;

		Item.Index   = i;
		Item.Texture = Settings.GetCrosshairLayer(i).Texture;
		Item.ScaleX  = Settings.GetCrosshairLayer(i).ScaleX;
		Item.ScaleY  = Settings.GetCrosshairLayer(i).ScaleY;
		Item.OffsetX = Settings.GetCrosshairLayer(i).OffsetX;
		Item.OffsetY = Settings.GetCrosshairLayer(i).OffsetY;
		Item.Color   = Settings.GetCrosshairLayer(i).Color;
		Item.Style   = Settings.GetCrosshairLayer(i).Style;
		Item.bSmooth = Settings.GetCrosshairLayer(i).bSmooth;

		if (Item.Style == 0)
			Item.Style = 1;

		LB_Layers.Items.AppendItem(Item);
	}
}

function Save() {
	local int i;
	local IGPlus_CrosshairLayersListItem L;
	local color White;

	White.R = 255;
	White.G = 255;
	White.B = 255;
	White.A = 255;

	i = 0;
	for (L = IGPlus_CrosshairLayersListItem(LB_Layers.Items.Next); L != none && i < 10; L = IGPlus_CrosshairLayersListItem(L.Next)) {
		Settings.SetCrosshairLayerUse(i, true);

		Settings.SetCrosshairLayerTexture(i, L.Texture);
		Settings.SetCrosshairLayerOffsetX(i, L.OffsetX);
		Settings.SetCrosshairLayerOffsetY(i, L.OffsetY);
		Settings.SetCrosshairLayerScaleX(i, L.ScaleX);
		Settings.SetCrosshairLayerScaleY(i, L.ScaleY);
		Settings.SetCrosshairLayerColor(i, L.Color);
		Settings.SetCrosshairLayerStyle(i, L.Style);
		Settings.SetCrosshairLayerSmooth(i, L.bSmooth);

		i++;
	}

	while(i < 10) {
		Settings.SetCrosshairLayerUse(i, false);

		Settings.SetCrosshairLayerTexture(i, "");
		Settings.SetCrosshairLayerOffsetX(i, 0);
		Settings.SetCrosshairLayerOffsetY(i, 0);
		Settings.SetCrosshairLayerScaleX(i, 1);
		Settings.SetCrosshairLayerScaleY(i, 1);
		Settings.SetCrosshairLayerColor(i, White);
		Settings.SetCrosshairLayerStyle(i, 0);
		Settings.SetCrosshairLayerSmooth(i, false);

		i++;
	}

	Settings.CreateCrosshairLayers();
	Settings.StoreCrosshairPreset(Edit_PresetName.GetValue());
	Settings.SaveConfig();
}

// The list of presets, with the picked one selected and its name in the box.
function LoadPresets() {
	local int i;
	local string PresetName;
	local IGPlus_CrosshairPresetsListItem Item;

	if (Settings == none)
		return;

	bUpdatingControls = true;
	LB_Presets.Items.Clear();
	LB_Presets.SelectedItem = none;
	for (i = 0; i < arraycount(Settings.CrosshairPresets); ++i) {
		PresetName = Settings.GetCrosshairPresetName(i);
		if (PresetName == "")
			continue;

		Item = IGPlus_CrosshairPresetsListItem(LB_Presets.Items.CreateItem(LB_Presets.ListClass));
		if (Item == none)
			continue;

		Item.Slot = i;
		Item.PresetName = PresetName;
		Item.Layers = Settings.CreateCrosshairPresetLayers(i);
		LB_Presets.Items.AppendItem(Item);

		if (i == Settings.CrosshairPreset) {
			LB_Presets.SetSelectedItem(Item);
			Edit_PresetName.SetValue(PresetName);
		}
	}
	bUpdatingControls = false;
}

function Load() {
	LB_Layers.Items.Clear();
	LB_Layers.SelectedItem = none;
	LastSelected = none;
	CopyCrosshairLayers();
	LoadPresets();
}

function Created() {
	super.Created();

	ParentDialog = IGPlus_CrosshairSettingsDialog(ParentWindow);

	LB_Layers = IGPlus_CrosshairLayersListBox(CreateControl(class'IGPlus_CrosshairLayersListBox', 10, 30, 256, 150));

	Btn_AddLayer = IGPlus_Button(CreateControl(class'IGPlus_Button', 10, 10, 16, 16));
	Btn_AddLayer.SetText("+");
	Btn_RemLayer = IGPlus_Button(CreateControl(class'IGPlus_Button', 30, 10, 16, 16));
	Btn_RemLayer.SetText("-");
	Btn_CopyCode = IGPlus_Button(CreateControl(class'IGPlus_Button', 56, 10, 64, 16));
	Btn_CopyCode.SetText(CopyCodeText);
	Btn_PasteCode = IGPlus_Button(CreateControl(class'IGPlus_Button', 124, 10, 64, 16));
	Btn_PasteCode.SetText(PasteCodeText);

	Lbl_Scale = IGPlus_Label(CreateControl(class'IGPlus_Label', 276, 10, 64, 16));
	Lbl_Scale.SetText(ScaleText);
	Lbl_Scale.SetHelpText("");
	Lbl_Scale.SetFont(F_Normal);
	Lbl_Scale.Align = TA_Center;

	Btn_ScaleUp = IGPlus_BtnUp(CreateControl(class'IGPlus_BtnUp', 302, 30, 12, 10));
	Btn_ScaleDown = IGPlus_BtnDown(CreateControl(class'IGPlus_BtnDown', 302, 60, 12, 10));
	Btn_ScaleLeft = IGPlus_BtnLeft(CreateControl(class'IGPlus_BtnLeft', 288, 44, 10, 12));
	Btn_ScaleRight = IGPlus_BtnRight(CreateControl(class'IGPlus_BtnRight', 318, 44, 10, 12));

	Lbl_Offset = IGPlus_Label(CreateControl(class'IGPlus_Label', 344, 10, 64, 16));
	Lbl_Offset.SetText(OffsetText);
	Lbl_Offset.SetHelpText("");
	Lbl_Offset.SetFont(F_Normal);
	Lbl_Offset.Align = TA_Center;

	Btn_OffsetUp = IGPlus_BtnUp(CreateControl(class'IGPlus_BtnUp', 370, 30, 12, 10));
	Btn_OffsetDown = IGPlus_BtnDown(CreateControl(class'IGPlus_BtnDown', 370, 60, 12, 10));
	Btn_OffsetLeft = IGPlus_BtnLeft(CreateControl(class'IGPlus_BtnLeft', 356, 44, 10, 12));
	Btn_OffsetRight = IGPlus_BtnRight(CreateControl(class'IGPlus_BtnRight', 386, 44, 10, 12));

	Edit_Texture = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 80, 150, 16));
	Edit_Texture.SetText(TextureText);
	Edit_Texture.SetFont(F_Normal);
	Edit_Texture.Align = TA_Left;
	Edit_Texture.SetHistory(true);
	Edit_Texture.SetDelayedNotify(true);
	Edit_Texture.SetNumericOnly(false);
	Edit_Texture.SetNumericFloat(false);
	Edit_Texture.EditBoxWidthFraction = (2.0/3.0);
	Edit_Texture.EditBoxWidth = 100;

	Edit_OffsetX = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 100, 150, 16));
	Edit_OffsetX.SetText(OffsetXText);
	Edit_OffsetX.SetFont(F_Normal);
	Edit_OffsetX.Align = TA_Left;
	Edit_OffsetX.SetHistory(true);
	Edit_OffsetX.SetDelayedNotify(true);
	Edit_OffsetX.SetNumericOnly(true);
	Edit_OffsetX.SetNumericFloat(false);
	Edit_OffsetX.SetNumericNegative(true);
	Edit_OffsetX.EditBoxWidthFraction = (1.0/3.0);
	Edit_OffsetX.EditBoxWidth = 50;

	Edit_OffsetY = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 120, 150, 16));
	Edit_OffsetY.SetText(OffsetYText);
	Edit_OffsetY.SetFont(F_Normal);
	Edit_OffsetY.Align = TA_Left;
	Edit_OffsetY.SetHistory(true);
	Edit_OffsetY.SetDelayedNotify(true);
	Edit_OffsetY.SetNumericOnly(true);
	Edit_OffsetY.SetNumericFloat(false);
	Edit_OffsetY.SetNumericNegative(true);
	Edit_OffsetY.EditBoxWidthFraction = (1.0/3.0);
	Edit_OffsetY.EditBoxWidth = 50;

	Edit_ScaleX = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 140, 150, 16));
	Edit_ScaleX.SetText(ScaleXText);
	Edit_ScaleX.SetFont(F_Normal);
	Edit_ScaleX.Align = TA_Left;
	Edit_ScaleX.SetHistory(true);
	Edit_ScaleX.SetDelayedNotify(true);
	Edit_ScaleX.SetNumericOnly(true);
	Edit_ScaleX.SetNumericFloat(true);
	Edit_ScaleX.EditBoxWidthFraction = (1.0/3.0);
	Edit_ScaleX.EditBoxWidth = 50;

	Edit_ScaleY = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 160, 150, 16));
	Edit_ScaleY.SetText(ScaleYText);
	Edit_ScaleY.SetFont(F_Normal);
	Edit_ScaleY.Align = TA_Left;
	Edit_ScaleY.SetHistory(true);
	Edit_ScaleY.SetDelayedNotify(true);
	Edit_ScaleY.SetNumericOnly(true);
	Edit_ScaleY.SetNumericFloat(true);
	Edit_ScaleY.EditBoxWidthFraction = (1.0/3.0);
	Edit_ScaleY.EditBoxWidth = 50;

	Edit_ColorRed = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 180, 150, 16));
	Edit_ColorRed.SetText(ColorRedText);
	Edit_ColorRed.SetFont(F_Normal);
	Edit_ColorRed.Align = TA_Left;
	Edit_ColorRed.SetHistory(true);
	Edit_ColorRed.SetDelayedNotify(true);
	Edit_ColorRed.SetNumericOnly(true);
	Edit_ColorRed.SetNumericFloat(false);
	Edit_ColorRed.EditBoxWidthFraction = (1.0/6.0);
	Edit_ColorRed.EditBoxWidth = 25;

	Edit_ColorGreen = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 200, 150, 16));
	Edit_ColorGreen.SetText(ColorGreenText);
	Edit_ColorGreen.SetFont(F_Normal);
	Edit_ColorGreen.Align = TA_Left;
	Edit_ColorGreen.SetHistory(true);
	Edit_ColorGreen.SetDelayedNotify(true);
	Edit_ColorGreen.SetNumericOnly(true);
	Edit_ColorGreen.SetNumericFloat(false);
	Edit_ColorGreen.EditBoxWidthFraction = (1.0/6.0);
	Edit_ColorGreen.EditBoxWidth = 25;

	Edit_ColorBlue = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 220, 150, 16));
	Edit_ColorBlue.SetText(ColorBlueText);
	Edit_ColorBlue.SetFont(F_Normal);
	Edit_ColorBlue.Align = TA_Left;
	Edit_ColorBlue.SetHistory(true);
	Edit_ColorBlue.SetDelayedNotify(true);
	Edit_ColorBlue.SetNumericOnly(true);
	Edit_ColorBlue.SetNumericFloat(false);
	Edit_ColorBlue.EditBoxWidthFraction = (1.0/6.0);
	Edit_ColorBlue.EditBoxWidth = 25;

	Edit_ColorAlpha = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 276, 240, 150, 16));
	Edit_ColorAlpha.SetText(ColorAlphaText);
	Edit_ColorAlpha.SetFont(F_Normal);
	Edit_ColorAlpha.Align = TA_Left;
	Edit_ColorAlpha.SetHistory(true);
	Edit_ColorAlpha.SetDelayedNotify(true);
	Edit_ColorAlpha.SetNumericOnly(true);
	Edit_ColorAlpha.SetNumericFloat(false);
	Edit_ColorAlpha.EditBoxWidthFraction = (1.0/6.0);
	Edit_ColorAlpha.EditBoxWidth = 25;

	Cmb_Style = IGPlus_ComboBox(CreateControl(class'IGPlus_ComboBox', 276, 260, 150, 16));
	Cmb_Style.SetText(StyleText);
	Cmb_Style.SetFont(F_Normal);
	Cmb_Style.Align = TA_Left;
	Cmb_Style.SetEditable(false);
	Cmb_Style.EditBoxWidthFraction = (2.0/3.0);
	Cmb_Style.EditBoxWidth = 100;
	Cmb_Style.AddItem(StyleNormal, "1");
	Cmb_Style.AddItem(StyleMasked, "2");
	Cmb_Style.AddItem(StyleTranslucent, "3");
	Cmb_Style.AddItem(StyleModulated, "4");

	Chk_Smooth = IGPlus_Checkbox(CreateControl(class'IGPlus_Checkbox', 276, 280, 150, 16));
	Chk_Smooth.SetText(SmoothText);
	Chk_Smooth.SetFont(F_Normal);
	Chk_Smooth.Align = TA_Left;

	Btn_AddPreset = IGPlus_Button(CreateControl(class'IGPlus_Button', 436, 10, 16, 16));
	Btn_AddPreset.SetText("+");
	Btn_RemPreset = IGPlus_Button(CreateControl(class'IGPlus_Button', 456, 10, 16, 16));
	Btn_RemPreset.SetText("-");

	Lbl_Presets = IGPlus_Label(CreateControl(class'IGPlus_Label', 480, 10, 106, 16));
	Lbl_Presets.SetText(PresetsText);
	Lbl_Presets.SetHelpText("");
	Lbl_Presets.SetFont(F_Normal);
	Lbl_Presets.Align = TA_Left;

	LB_Presets = IGPlus_CrosshairPresetsListBox(CreateControl(class'IGPlus_CrosshairPresetsListBox', 436, 30, 150, 374));
	LB_Presets.BackgroundBrightness = ParentDialog.BackgroundBrightness;

	Edit_PresetName = IGPlus_EditControl(CreateControl(class'IGPlus_EditControl', 436, 408, 150, 16));
	Edit_PresetName.SetText(PresetNameText);
	Edit_PresetName.SetFont(F_Normal);
	Edit_PresetName.Align = TA_Left;
	Edit_PresetName.SetDelayedNotify(true);
	Edit_PresetName.SetNumericOnly(false);
	Edit_PresetName.SetNumericFloat(false);
	Edit_PresetName.SetMaxLength(32);
	Edit_PresetName.EditBoxWidthFraction = (3.0/4.0);
	Edit_PresetName.EditBoxWidth = 112;

	Btn_Close = UWindowSmallCloseButton(CreateControl(class'UWindowSmallCloseButton', 554, 430, 32, 16));
	Btn_Save = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 518, 430, 32, 16));
	Btn_Save.SetText(class'IGPlus_SettingsScroll'.default.SaveButtonText);
}

// The layers in the list, as a share code.
function string MakeShareCode() {
	local IGPlus_CrosshairLayersListItem L;
	local string Code;
	local int n;

	Code = IGPLUS_CH_CODE_PREFIX;
	for (L = IGPlus_CrosshairLayersListItem(LB_Layers.Items.Next); L != none && n < 10; L = IGPlus_CrosshairLayersListItem(L.Next)) {
		if (n > 0)
			Code = Code $ ";";
		Code = Code $ L.Texture
			$ "," $ L.OffsetX $ "," $ L.OffsetY
			$ "," $ class'StringUtils'.static.FormatFloat(L.ScaleX, 3)
			$ "," $ class'StringUtils'.static.FormatFloat(L.ScaleY, 3)
			$ "," $ L.Color.R $ "," $ L.Color.G $ "," $ L.Color.B $ "," $ L.Color.A
			$ "," $ L.Style;
		if (L.bSmooth)
			Code = Code $ ",1";
		else
			Code = Code $ ",0";
		n++;
	}
	return Code;
}

// The text up to Sep, taken off the front of S. All of S when Sep isn't in it.
static function string NextToken(out string S, string Sep) {
	local int i;
	local string T;

	i = InStr(S, Sep);
	if (i < 0) {
		T = S;
		S = "";
	} else {
		T = Left(S, i);
		S = Mid(S, i + Len(Sep));
	}
	return T;
}

// A texture name of a code: Package.Name, letters, digits, '_' and '.' only,
// and short. Empty is the default texture.
static function bool IsSafeTextureName(string T) {
	local int i, c;

	if (Len(T) > 64)
		return false;
	for (i = 0; i < Len(T); i++) {
		c = Asc(Mid(T, i, 1));
		if ((c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 46)
			continue;
		return false;
	}
	return true;
}

// A whole number of a code: an optional '-' and digits, nothing else.
static function bool IsIntToken(string T) {
	local int i, c;

	if (Len(T) == 0 || Len(T) > 6)
		return false;
	for (i = 0; i < Len(T); i++) {
		c = Asc(Mid(T, i, 1));
		if (c >= 48 && c <= 57)
			continue;
		if (i == 0 && c == 45 && Len(T) > 1)
			continue;
		return false;
	}
	return true;
}

// A decimal of a code: an optional '-', digits and at most one '.'.
static function bool IsFloatToken(string T) {
	local int i, c, Dots;

	if (Len(T) == 0 || Len(T) > 12)
		return false;
	for (i = 0; i < Len(T); i++) {
		c = Asc(Mid(T, i, 1));
		if (c >= 48 && c <= 57)
			continue;
		if (c == 46 && Dots == 0) {
			Dots++;
			continue;
		}
		if (i == 0 && c == 45 && Len(T) > 1)
			continue;
		return false;
	}
	return true;
}

// Reads a share code into the list of layers. Nothing changes unless the
// whole code is good: the prefix, 1 to 10 layers of 11 fields, every field
// of its kind. Numbers are clamped to sane ranges.
function bool ApplyShareCode(string Code) {
	local string Rest, LayerStr, F[11];
	local string Textures[10];
	local int Ints[100];
	local float Scales[20];
	local int n, i, k;
	local IGPlus_CrosshairLayersListItem Item;

	Code = class'StringUtils'.static.Trim(Code);
	if (Left(Code, Len(IGPLUS_CH_CODE_PREFIX)) != IGPLUS_CH_CODE_PREFIX)
		return false;
	Rest = Mid(Code, Len(IGPLUS_CH_CODE_PREFIX));
	if (Len(Rest) == 0 || Len(Rest) > 2000)
		return false;

	while (Len(Rest) > 0) {
		if (n >= 10)
			return false;
		LayerStr = NextToken(Rest, ";");
		for (i = 0; i < 11; i++) {
			if (i > 0 && Len(LayerStr) == 0)
				return false; // too few fields
			F[i] = NextToken(LayerStr, ",");
		}
		if (Len(LayerStr) > 0)
			return false; // too many fields
		if (IsSafeTextureName(F[0]) == false)
			return false;
		for (i = 1; i < 11; i++) {
			if (i == 3 || i == 4) {
				if (IsFloatToken(F[i]) == false)
					return false;
			} else if (IsIntToken(F[i]) == false) {
				return false;
			}
		}
		Textures[n] = F[0];
		Ints[n*10 + 0] = Clamp(int(F[1]), -4096, 4096);  // OffsetX
		Ints[n*10 + 1] = Clamp(int(F[2]), -4096, 4096);  // OffsetY
		Scales[n*2 + 0] = FClamp(float(F[3]), 0.01, 64.0);
		Scales[n*2 + 1] = FClamp(float(F[4]), 0.01, 64.0);
		Ints[n*10 + 2] = Clamp(int(F[5]), 0, 255);       // R
		Ints[n*10 + 3] = Clamp(int(F[6]), 0, 255);       // G
		Ints[n*10 + 4] = Clamp(int(F[7]), 0, 255);       // B
		Ints[n*10 + 5] = Clamp(int(F[8]), 0, 255);       // A
		Ints[n*10 + 6] = Clamp(int(F[9]), 1, 4);         // Style
		Ints[n*10 + 7] = Clamp(int(F[10]), 0, 1);        // Smooth
		n++;
	}
	if (n == 0)
		return false;

	LB_Layers.Items.Clear();
	for (k = 0; k < n; k++) {
		Item = IGPlus_CrosshairLayersListItem(LB_Layers.Items.CreateItem(LB_Layers.ListClass));
		if (Item == none)
			continue;
		Item.Index   = k;
		Item.Texture = Textures[k];
		Item.Tex     = none;
		Item.OffsetX = Ints[k*10 + 0];
		Item.OffsetY = Ints[k*10 + 1];
		Item.ScaleX  = Scales[k*2 + 0];
		Item.ScaleY  = Scales[k*2 + 1];
		Item.Color.R = Ints[k*10 + 2];
		Item.Color.G = Ints[k*10 + 3];
		Item.Color.B = Ints[k*10 + 4];
		Item.Color.A = Ints[k*10 + 5];
		Item.Style   = Ints[k*10 + 6];
		Item.bSmooth = Ints[k*10 + 7] != 0;
		LB_Layers.Items.AppendItem(Item);
	}
	return true;
}

function int FindHighestIndex() {
	local int i;
	local IGPlus_CrosshairLayersListItem Item;

	i = -1;
	for (Item = IGPlus_CrosshairLayersListItem(LB_Layers.Items.Next); Item != none; Item = IGPlus_CrosshairLayersListItem(Item.Next))
		i = Max(i, Item.Index);

	return i;
}

function AddLayer() {
	local IGPlus_CrosshairLayersListItem Item;

	Item = IGPlus_CrosshairLayersListItem(LB_Layers.Items.CreateItem(LB_Layers.ListClass));
	if (Item == none)
		return;

	Item.Index   = FindHighestIndex()+1;
	Item.Texture = "";
	Item.ScaleX  = 1;
	Item.ScaleY  = 1;
	Item.OffsetX = 0;
	Item.OffsetY = 0;
	Item.Color.R = 255;
	Item.Color.G = 255;
	Item.Color.B = 255;
	Item.Color.A = 255;
	Item.Style   = 1;
	Item.bSmooth = false;

	LB_Layers.Items.AppendItem(Item);
}

function RemLayer() {
	LB_Layers.SelectedItem.Remove();
	LB_Layers.SelectedItem = none;
}

function FillControlsFor(IGPlus_CrosshairLayersListItem L) {
	if (L == none) {
		Edit_Texture.Clear();

		Edit_OffsetX.Clear();
		Edit_OffsetY.Clear();
		Edit_ScaleX.Clear();
		Edit_ScaleY.Clear();

		Edit_ColorRed.Clear();
		Edit_ColorGreen.Clear();
		Edit_ColorBlue.Clear();
		Edit_ColorAlpha.Clear();

		Cmb_Style.ClearValue();
	} else {
		Edit_Texture.SetValue(L.Texture);

		Edit_OffsetX.SetValue(string(L.OffsetX));
		Edit_OffsetY.SetValue(string(L.OffsetY));
		Edit_ScaleX.SetValue(string(L.ScaleX));
		Edit_ScaleY.SetValue(string(L.ScaleY));

		Edit_ColorRed.SetValue(string(L.Color.R));
		Edit_ColorGreen.SetValue(string(L.Color.G));
		Edit_ColorBlue.SetValue(string(L.Color.B));
		Edit_ColorAlpha.SetValue(string(L.Color.A));

		Cmb_Style.SetSelectedIndex(L.Style - 1);
		Chk_Smooth.bChecked = L.bSmooth;
	}
}

function Notify(UWindowDialogControl C, byte E) {
	local int Slot;

	if (bUpdatingControls)
		return;

	if (E == DE_Click) {
		if (C == Btn_AddLayer && Btn_AddLayer.bDisabled == false) {
			AddLayer();
		} else if (C == Btn_RemLayer && Btn_RemLayer.bDisabled == false) {
			RemLayer();
		} else if (C == Btn_AddPreset && Btn_AddPreset.bDisabled == false) {
			// The new preset is a copy. The layers shown stay as they are,
			// and Save writes them into the new preset.
			if (Settings.NewCrosshairPreset())
				LoadPresets();
		} else if (C == Btn_RemPreset && Btn_RemPreset.bDisabled == false) {
			if (Settings.DeleteCrosshairPreset())
				Load();
		} else if (C == LB_Presets && LB_Presets.SelectedItem != none) {
			// Another preset: drawn in the game from this click on.
			Slot = IGPlus_CrosshairPresetsListItem(LB_Presets.SelectedItem).Slot;
			if (Slot != Settings.CrosshairPreset) {
				Settings.PickCrosshairPreset(Slot);
				Load();
			}
		} else if (C == Btn_ScaleUp && Btn_ScaleUp.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleY += 1;
			bUpdatingControls = true;
			Edit_ScaleY.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleY));
			bUpdatingControls = false;
		} else if (C == Btn_ScaleDown && Btn_ScaleDown.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleY -= 1;
			bUpdatingControls = true;
			Edit_ScaleY.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleY));
			bUpdatingControls = false;
		} else if (C == Btn_ScaleLeft && Btn_ScaleLeft.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleX -= 1;
			bUpdatingControls = true;
			Edit_ScaleX.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleX));
			bUpdatingControls = false;
		} else if (C == Btn_ScaleRight && Btn_ScaleRight.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleX += 1;
			bUpdatingControls = true;
			Edit_ScaleX.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleX));
			bUpdatingControls = false;
		} else if (C == Btn_OffsetUp && Btn_OffsetUp.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetY -= 1;
			bUpdatingControls = true;
			Edit_OffsetY.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetY));
			bUpdatingControls = false;
		} else if (C == Btn_OffsetDown && Btn_OffsetDown.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetY += 1;
			bUpdatingControls = true;
			Edit_OffsetY.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetY));
			bUpdatingControls = false;
		} else if (C == Btn_OffsetLeft && Btn_OffsetLeft.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetX -= 1;
			bUpdatingControls = true;
			Edit_OffsetX.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetX));
			bUpdatingControls = false;
		} else if (C == Btn_OffsetRight && Btn_OffsetRight.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetX += 1;
			bUpdatingControls = true;
			Edit_OffsetX.SetValue(string(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetX));
			bUpdatingControls = false;
		} else if (C == LB_Layers && LastSelected != LB_Layers.SelectedItem) {
			bUpdatingControls = true;
			FillControlsFor(IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem));
			LastSelected = LB_Layers.SelectedItem;
			bUpdatingControls = false;
		} else if (C == Btn_Save) {
			Save();
			Load();
		} else if (C == Btn_CopyCode) {
			GetPlayerOwner().CopyToClipboard(MakeShareCode());
			GetPlayerOwner().ClientMessage(CodeCopiedText);
		} else if (C == Btn_PasteCode) {
			if (ApplyShareCode(GetPlayerOwner().PasteFromClipboard())) {
				LB_Layers.SelectedItem = none;
				LastSelected = none;
				bUpdatingControls = true;
				FillControlsFor(none);
				bUpdatingControls = false;
				GetPlayerOwner().ClientMessage(CodePastedText);
			} else {
				GetPlayerOwner().ClientMessage(CodeBadText);
			}
		}
	} else if (E == DE_Change) {
		if (C == Edit_Texture && Edit_Texture.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Texture = Edit_Texture.GetValue();
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Tex = none;
		} else if (C == Edit_OffsetX && Edit_OffsetX.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetX = int(Edit_OffsetX.GetValue());
		} else if (C == Edit_OffsetY && Edit_OffsetY.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).OffsetY = int(Edit_OffsetY.GetValue());
		} else if (C == Edit_ScaleX && Edit_ScaleX.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleX = float(Edit_ScaleX.GetValue());
		} else if (C == Edit_ScaleY && Edit_ScaleY.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).ScaleY = float(Edit_ScaleY.GetValue());
		} else if (C == Edit_ColorRed && Edit_ColorRed.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Color.R = byte(Edit_ColorRed.GetValue());
		} else if (C == Edit_ColorGreen && Edit_ColorGreen.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Color.G = byte(Edit_ColorGreen.GetValue());
		} else if (C == Edit_ColorBlue && Edit_ColorBlue.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Color.B = byte(Edit_ColorBlue.GetValue());
		} else if (C == Edit_ColorAlpha && Edit_ColorAlpha.EditBox.bCanEdit) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Color.A = byte(Edit_ColorAlpha.GetValue());
		} else if (C == Cmb_Style && LB_Layers.SelectedItem != none) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).Style = int(Cmb_Style.GetValue2()) + 1;
		} else if (C == Chk_Smooth && Chk_Smooth.bDisabled == false) {
			IGPlus_CrosshairLayersListItem(LB_Layers.SelectedItem).bSmooth = Chk_Smooth.bChecked;
		}
	}
}

function BeforePaint(Canvas C, float X, float Y) {
	local bool HaveSelectedItem;
	local bool HaveNoSelectedItem;

	super.BeforePaint(C, X, Y);

	HaveSelectedItem = LB_Layers.SelectedItem != none;
	HaveNoSelectedItem = LB_Layers.SelectedItem == none;

	Btn_AddLayer.bDisabled = LB_Layers.Items.Count() >= 10;
	Btn_RemLayer.bDisabled = (LB_Layers.Items.Count() <= 0 || HaveNoSelectedItem);

	Btn_AddPreset.bDisabled = LB_Presets.Items.Count() >= 16;
	Btn_RemPreset.bDisabled = LB_Presets.Items.Count() <= 1;

	Btn_ScaleUp.bDisabled = HaveNoSelectedItem;
	Btn_ScaleDown.bDisabled = HaveNoSelectedItem;
	Btn_ScaleLeft.bDisabled = HaveNoSelectedItem;
	Btn_ScaleRight.bDisabled = HaveNoSelectedItem;

	Btn_OffsetUp.bDisabled = HaveNoSelectedItem;
	Btn_OffsetDown.bDisabled = HaveNoSelectedItem;
	Btn_OffsetLeft.bDisabled = HaveNoSelectedItem;
	Btn_OffsetRight.bDisabled = HaveNoSelectedItem;

	Edit_Texture.EditBox.bCanEdit = HaveSelectedItem;

	Edit_OffsetX.EditBox.bCanEdit = HaveSelectedItem;
	Edit_OffsetY.EditBox.bCanEdit = HaveSelectedItem;
	Edit_ScaleX.EditBox.bCanEdit = HaveSelectedItem;
	Edit_ScaleY.EditBox.bCanEdit = HaveSelectedItem;

	Edit_ColorRed.EditBox.bCanEdit = HaveSelectedItem;
	Edit_ColorGreen.EditBox.bCanEdit = HaveSelectedItem;
	Edit_ColorBlue.EditBox.bCanEdit = HaveSelectedItem;
	Edit_ColorAlpha.EditBox.bCanEdit = HaveSelectedItem;

	if (Edit_Texture.EditBox.bCanEdit == false)
		Edit_Texture.Clear();

	if (Edit_OffsetX.EditBox.bCanEdit == false)
		Edit_OffsetX.Clear();
	if (Edit_OffsetY.EditBox.bCanEdit == false)
		Edit_OffsetY.Clear();
	if (Edit_ScaleX.EditBox.bCanEdit == false)
		Edit_ScaleX.Clear();
	if (Edit_ScaleY.EditBox.bCanEdit == false)
		Edit_ScaleY.Clear();

	if (Edit_ColorRed.EditBox.bCanEdit == false)
		Edit_ColorRed.Clear();
	if (Edit_ColorGreen.EditBox.bCanEdit == false)
		Edit_ColorGreen.Clear();
	if (Edit_ColorBlue.EditBox.bCanEdit == false)
		Edit_ColorBlue.Clear();
	if (Edit_ColorAlpha.EditBox.bCanEdit == false)
		Edit_ColorAlpha.Clear();

	Chk_Smooth.bDisabled = HaveNoSelectedItem;
}

function DrawCrosshairLayer(Canvas C, IGPlus_CrosshairLayersListItem L) {
	local float Scal;
	local float LenX, LenY;

	Scal = 4;

	if (L.Tex == none) {
		if (L.Texture == "")
			L.Tex = class'IGPlus_Assets'.static.Tex(Texture'CrossHairBase', "CrossHairBase");
		else
			L.Tex = Texture(DynamicLoadObject(L.Texture, class'Texture'));
	}

	if (L.Style == 0)
		L.Style = 1;

	C.Style = L.Style;
	C.DrawColor = L.Color;
	C.bNoSmooth = (L.bSmooth == false);

	LenX = L.ScaleX * L.Tex.USize * Scal;
	LenY = L.ScaleY * L.Tex.VSize * Scal;

	if (L == LB_Layers.SelectedItem) {
		C.DrawColor = L.Color;
		C.DrawColor.R = C.DrawColor.R ^ 0xFF;
		C.DrawColor.G = C.DrawColor.G ^ 0xFF;
		C.DrawColor.B = C.DrawColor.B ^ 0xFF;
		C.DrawColor.A = C.DrawColor.A ^ 0xFF;
		DrawStretchedTexture(C, 128 - 0.5*LenX + (L.OffsetX*Scal), 128 - 0.5*LenY + (L.OffsetY*Scal), LenX, LenY, L.Tex);

		C.DrawColor = L.Color;
		DrawStretchedTexture(C, 128 - 0.5*LenX + (L.OffsetX*Scal) + 1, 128 - 0.5*LenY + (L.OffsetY*Scal) + 1, LenX-2, LenY-2, L.Tex);
	} else {
		DrawStretchedTexture(C, 128 - 0.5*LenX + (L.OffsetX*Scal), 128 - 0.5*LenY + (L.OffsetY*Scal), LenX, LenY, L.Tex);
	}
}

function DrawCrosshair(Canvas C) {
	local IGPlus_CrosshairLayersListItem L;

	for (L = IGPlus_CrosshairLayersListItem(LB_Layers.Items.Next); L != none; L = IGPlus_CrosshairLayersListItem(L.Next))
		DrawCrosshairLayer(C, L);
}

function Paint(Canvas C, float X, float Y) {
	super.Paint(C, X, Y);

	class'CanvasUtils'.static.SaveCanvas(C);

	C.OrgX += int(10 * Root.GUIScale);
	C.OrgY += int(190 * Root.GUIScale);

	C.ClipX = 256 * Root.GUIScale;
	C.ClipY = 256 * Root.GUIScale;

	C.DrawColor.R = ParentDialog.BackgroundBrightness;
	C.DrawColor.G = ParentDialog.BackgroundBrightness;
	C.DrawColor.B = ParentDialog.BackgroundBrightness;
	C.DrawColor.A = 255;
	DrawStretchedTexture(C, 0, 0, 256, 256, Texture'WhiteTexture');

	C.DrawColor.R = C.DrawColor.R ^ 0xFF;
	C.DrawColor.G = C.DrawColor.G ^ 0xFF;
	C.DrawColor.B = C.DrawColor.B ^ 0xFF;
	C.DrawColor.A = 255;
	DrawStretchedTexture(C, 127, 0, 2, 256, class'IGPlus_Assets'.static.Tex(Texture'CrossHairBase', "CrossHairBase"));
	DrawStretchedTexture(C, 0, 127, 256, 2, class'IGPlus_Assets'.static.Tex(Texture'CrossHairBase', "CrossHairBase"));

	DrawCrosshair(C);

	class'CanvasUtils'.static.RestoreCanvas(C);
}

defaultproperties {
	CopyCodeText="Copy Code"
	PasteCodeText="Paste Code"
	CodeCopiedText="Crosshair code copied to the clipboard"
	CodePastedText="Crosshair code pasted: press Save to keep it"
	CodeBadText="The clipboard holds no valid crosshair code (IGCH1:...)"
	ScaleText="Scale"
	OffsetText="Offset"
	TextureText="Texture"

	OffsetXText="Offset X"
	OffsetYText="Offset Y"
	ScaleXText="Scale X"
	ScaleYText="Scale Y"

	ColorRedText="Red"
	ColorGreenText="Green"
	ColorBlueText="Blue"
	ColorAlphaText="Alpha"

	StyleText="Style"
	StyleNormal="Normal"
	StyleMasked="Masked"
	StyleTranslucent="Translucent"
	StyleModulated="Modulated"

	SmoothText="Smooth"

	PresetsText="Presets"
	PresetNameText="Name"
}
