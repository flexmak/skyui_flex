﻿import skyui.defines.Actor;
import skyui.defines.Armor;
import skyui.defines.Form;
import skyui.defines.Item;
import skyui.defines.Material;
import skyui.defines.Weapon;
import skyui.defines.Inventory;

class InventoryDataSetter extends ItemcardDataExtender
{
  /* PRIVATE VARIABLES */

	private var _combinedValue: Boolean;
	private var _combinedWeight: Boolean;

  /* PUBLIC FUNCTIONS */

	public function InventoryDataSetter(a_configItemList: Object, a_configAppearance: Object)
	{
		super();
		
		_combinedValue	= a_configItemList.inventory.combinedValue;
		_combinedWeight	= a_configItemList.inventory.combinedWeight;
	}

	// @override ItemcardDataExtender
	public function processEntry(a_entryObject: Object, a_itemInfo: Object): Void
	{
		//skyui.util.Debug.dump("a_entryObject", a_entryObject);
		//skyui.util.Debug.dump("a_itemInfo", a_itemInfo);

		a_entryObject.baseId = a_entryObject.formId & 0x00FFFFFF;
		a_entryObject.type = a_itemInfo.type;
		a_entryObject.value = a_itemInfo.value;// * (_sortByCombinedValue ? a_entryObject.count : 1);
		a_entryObject.weight = a_itemInfo.weight;// * (_sortByCombinedWeight ? a_entryObject.count : 1);
		a_entryObject.armor = a_itemInfo.armor;
		a_entryObject.damage = a_itemInfo.damage;

		a_entryObject.valueWeight = (a_itemInfo.weight > 0) ? (a_itemInfo.value / a_itemInfo.weight) : ((a_itemInfo.value != 0) ? undefined : 0); // 0/0 = 0

		a_entryObject.isEquipped = (a_entryObject.equipState > 0);
		a_entryObject.isStolen = (a_itemInfo.stolen == true);
		a_entryObject.isEnchanted = false;
		a_entryObject.isPoisoned = false;

		a_entryObject.valueDisplay = String(Math.round(a_itemInfo.value * 10) / 10) + ((_combinedValue == true && a_entryObject.count > 1 && a_itemInfo.value > 0) ? (" (" + String(Math.round(a_itemInfo.value * a_entryObject.count * 10) / 10) + ")") : "");
		a_entryObject.weightDisplay = String(Math.round(a_itemInfo.weight * 10) / 10) + ((_combinedWeight == true && a_entryObject.count > 1 && a_itemInfo.weight > 0) ? (" (" + String(Math.round(a_itemInfo.weight * a_entryObject.count * 10) / 10) + ")") : "");
		a_entryObject.valueWeightDisplay = (a_entryObject.valueWeight != undefined) ? (Math.round(a_entryObject.valueWeight * 10) / 10) : "-"; // Any item without a weight but has value has a valueWeight == undefined, so should be displayed as "-"
		a_entryObject.armorDisplay = (a_entryObject.armor > 0) ? (Math.round(a_entryObject.armor * 10) / 10) : "-";
		a_entryObject.damageDisplay = (a_entryObject.damage > 0) ? (Math.round(a_entryObject.damage * 10) / 10) : "-";

		a_entryObject.subTypeDisplay = "-";
		a_entryObject.materialDisplay = "-";
		a_entryObject.weightClassDisplay = "-";

		switch (a_entryObject.formType) {
			case Form.FORMTYPE_SCROLLITEM:
				a_entryObject.subTypeDisplay = "$Scroll";
				break;

			case Form.FORMTYPE_ARMOR:
				a_entryObject.isEnchanted = (a_itemInfo.effects != "");
				processArmorClass(a_entryObject);
				processArmorPartMask(a_entryObject);
				processMaterialKeywords(a_entryObject);

				//Move this to the specific DataProcessor
				processArmorOther(a_entryObject);
				break;

			case Form.FORMTYPE_BOOK:
				processBookType(a_entryObject);
				break;

			case Form.FORMTYPE_INGREDIENT:
				a_entryObject.subTypeDisplay = "$Ingredient";
				break;

			case Form.FORMTYPE_LIGHT:
				a_entryObject.subTypeDisplay = "$Torch";
				break;

			case Form.FORMTYPE_MISC:
				processMiscType(a_entryObject);
				break;

			case Form.FORMTYPE_WEAPON:
				a_entryObject.isEnchanted = (a_itemInfo.effects != "");
				a_entryObject.isPoisoned = (a_itemInfo.poisoned == true); 
				processWeaponType(a_entryObject);
				processMaterialKeywords(a_entryObject);
				break;

			case Form.FORMTYPE_AMMO:
				a_entryObject.isEnchanted = (a_itemInfo.effects != "");
				processAmmoType(a_entryObject);
				processMaterialKeywords(a_entryObject);
				///processAmmoFormIDs(a_entryObject); //Vanilla arrows don't have material keywords
				break;

			case Form.FORMTYPE_KEY:
				processKeyType(a_entryObject);
				break;

			case Form.FORMTYPE_POTION:
				processPotionType(a_entryObject);
				break;

			case Form.FORMTYPE_SOULGEM:
				processSoulGemType(a_entryObject);
				processSoulGemStatus(a_entryObject);
				break;
		}
	}

  /* PRIVATE FUNCTIONS */

	private function processArmorClass(a_entryObject: Object): Void
	{
		if (a_entryObject.weightClass == Armor.WEIGHTCLASS_NONE)
			a_entryObject.weightClass = Armor.OTHER
		a_entryObject.weightClassDisplay = "$Other";

		switch (a_entryObject.weightClass) {
			case Armor.WEIGHTCLASS_LIGHT:
				a_entryObject.weightClassDisplay = "$Light";
				break;

			case Armor.WEIGHTCLASS_HEAVY:
				a_entryObject.weightClassDisplay = "$Heavy";
				break;

			default:
				if (a_entryObject.keywords == undefined)
					break;

				if (a_entryObject.keywords["VendorItemClothing"] != undefined) {
					a_entryObject.weightClass = Armor.WEIGHTCLASS_CLOTHING;
					a_entryObject.weightClassDisplay = "$Clothing";
				} else if (a_entryObject.keywords["VendorItemJewelry"] != undefined) {
					a_entryObject.weightClass = Armor.WEIGHTCLASS_JEWELRY;
					a_entryObject.weightClassDisplay = "$Jewelry";
				}	 
		}
	}

	private function processMaterialKeywords(a_entryObject: Object): Void
	{
		a_entryObject.material = Material.OTHER;
		a_entryObject.materialDisplay = "$Other";

		if (a_entryObject.keywords == undefined)
			return;

		if (a_entryObject.keywords["ArmorMaterialDaedric"] != undefined ||
			a_entryObject.keywords["WeapMaterialDaedric"] != undefined) {
			a_entryObject.material = Material.DAEDRIC;
			a_entryObject.materialDisplay = "$Daedric";
		
		} else if (a_entryObject.keywords["ArmorMaterialDragonplate"] != undefined) {
			a_entryObject.material = Material.DRAGONPLATE;
			a_entryObject.materialDisplay = "$Dragon Plate";
		
		} else if (a_entryObject.keywords["ArmorMaterialDragonscale"] != undefined) {
			a_entryObject.material = Material.DRAGONSCALE;
			a_entryObject.materialDisplay = "$Dragon Scale";
		
		} else if (a_entryObject.keywords["ArmorMaterialDwarven"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialDwarven"] != undefined) {
			a_entryObject.material = Material.DWARVEN;
			a_entryObject.materialDisplay = "$Dwarven";
		
		} else if (a_entryObject.keywords["ArmorMaterialEbony"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialEbony"] != undefined) {
			a_entryObject.material = Material.EBONY;
			a_entryObject.materialDisplay = "$Ebony";
		
		} else if (a_entryObject.keywords["ArmorMaterialElven"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialElven"] != undefined) {
			a_entryObject.material = Material.ELVEN;
			a_entryObject.materialDisplay = "$Elven";
		
		} else if (a_entryObject.keywords["ArmorMaterialElvenGilded"] != undefined) {
			a_entryObject.material = Material.ELVENGILDED;
			a_entryObject.materialDisplay = "$Elven Gilded";
		
		} else if (a_entryObject.keywords["ArmorMaterialGlass"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialGlass"] != undefined) {
			a_entryObject.material = Material.GLASS;
			a_entryObject.materialDisplay = "$Glass";
		
		} else if (a_entryObject.keywords["ArmorMaterialHide"] != undefined) {
			a_entryObject.material = Material.HIDE;
			a_entryObject.materialDisplay = "$Hide";
		
		} else if (a_entryObject.keywords["ArmorMaterialImperialHeavy"] != undefined ||
		 		   a_entryObject.keywords["ArmorMaterialImperialLight"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialImperial"] != undefined) {
			a_entryObject.material = Material.IMPERIAL;
			a_entryObject.materialDisplay = "$Imperial";
		
		} else if (a_entryObject.keywords["ArmorMaterialImperialStudded"] != undefined) {
			a_entryObject.material = Material.IMPERIALSTUDDED;
			a_entryObject.materialDisplay = "$Imperial Studded";
		
		} else if (a_entryObject.keywords["ArmorMaterialIron"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialIron"] != undefined) {
			a_entryObject.material = Material.IRON;
			a_entryObject.materialDisplay = "$Iron";
		
		} else if (a_entryObject.keywords["ArmorMaterialIronBanded"] != undefined) {
			a_entryObject.material = Material.IRONBANDED;
			a_entryObject.materialDisplay = "$Iron Banded";
		
		} else if (a_entryObject.keywords["ArmorMaterialLeather"] != undefined) {
			a_entryObject.material = Material.LEATHER;
			a_entryObject.materialDisplay = "$Leather";
		
		} else if (a_entryObject.keywords["ArmorMaterialOrcish"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialOrcish"] != undefined) {
			a_entryObject.material = Material.ORCISH;
			a_entryObject.materialDisplay = "$Orcish";
		
		} else if (a_entryObject.keywords["ArmorMaterialScaled"] != undefined) {
			a_entryObject.material = Material.SCALED;
			a_entryObject.materialDisplay = "$Scaled";
		
		} else if (a_entryObject.keywords["ArmorMaterialSteel"] != undefined ||
		 		   a_entryObject.keywords["WeapMaterialSteel"] != undefined) {
			a_entryObject.material = Material.STEEL;
			a_entryObject.materialDisplay = "$Steel";
		
		} else if (a_entryObject.keywords["ArmorMaterialSteelPlate"] != undefined) {
			a_entryObject.material = Material.STEELPLATE;
			a_entryObject.materialDisplay = "$Steel Plate";
		
		} else if (a_entryObject.keywords["ArmorMaterialStormcloak"] != undefined) {
			a_entryObject.material = Material.STORMCLOAK;
			a_entryObject.materialDisplay = "$Stormcloak";
		
		} else if (a_entryObject.keywords["ArmorMaterialStudded"] != undefined) {
			a_entryObject.material = Material.STUDDED;
			a_entryObject.materialDisplay = "$Studded";
		
		} else if (a_entryObject.keywords["DLC1ArmorMaterialDawnguard"] != undefined) {
			a_entryObject.material = Material.DAWNGUARD;
			a_entryObject.materialDisplay = "$Dawnguard";
		
		} else if (a_entryObject.keywords["DLC1ArmorMaterialFalmerHardened"] != undefined) {
			a_entryObject.material = Material.FALMERHARDENED;
			a_entryObject.materialDisplay = "$Falmer Hardened";
		
		} else if (a_entryObject.keywords["DLC1ArmorMaterialHunter"] != undefined) {
			a_entryObject.material = Material.HUNTER;
			a_entryObject.materialDisplay = "$Hunter";
		
		} else if (a_entryObject.keywords["DLC1ArmorMaterialVampire"] != undefined) {
			a_entryObject.material = Material.VAMPIRE;
			a_entryObject.materialDisplay = "$Vampire";
		
		} else if (a_entryObject.keywords["DLC1LD_CraftingMaterialAetherium"] != undefined) {
			a_entryObject.material = Material.AETHERIUM;
			a_entryObject.materialDisplay = "$Aetherium";
		
		} else if (a_entryObject.keywords["DLC1WeapMaterialDragonbone"] != undefined) {
			a_entryObject.material = Material.DRAGONBONE;
			a_entryObject.materialDisplay = "$Dragonbone";
		
		} else if (a_entryObject.keywords["DLC2ArmorMaterialBonemoldHeavy"] != undefined ||
		 		   a_entryObject.keywords["DLC2ArmorMaterialBonemoldLight"] != undefined) {
			a_entryObject.material = Material.BONEMOLD;
			a_entryObject.materialDisplay = "$Bonemold";

		} else if (a_entryObject.keywords["DLC2ArmorMaterialChitinHeavy"] != undefined ||
		 		   a_entryObject.keywords["DLC2ArmorMaterialChitinLight"] != undefined) {
			a_entryObject.material = Material.CHITIN;
			a_entryObject.materialDisplay = "$Chitin";
		
		} else if (a_entryObject.keywords["DLC2ArmorMaterialMoragTong"] != undefined) {
			a_entryObject.material = Material.MORAGTONG;
			a_entryObject.materialDisplay = "$Morag Tong";
		
		} else if (a_entryObject.keywords["DLC2ArmorMaterialNordicHeavy"] != undefined ||
		 		   a_entryObject.keywords["DLC2ArmorMaterialNordicLight"] != undefined ||
		 		   a_entryObject.keywords["DLC2WeapMaterialNordic"] != undefined) {
			a_entryObject.material = Material.NORDIC;
			a_entryObject.materialDisplay = "$Nordic";
		
		} else if (a_entryObject.keywords["DLC2ArmorMaterialStahlrimHeavy"] != undefined ||
		 		   a_entryObject.keywords["DLC2ArmorMaterialStahlrimLight"] != undefined ||
		 		   a_entryObject.keywords["DLC2WeapMaterialStahlrim"] != undefined) {
			a_entryObject.material = Material.STAHLRIM;
			a_entryObject.materialDisplay = "$Stahlrim";
			if (a_entryObject.keywords["DLC2dunHaknirArmor"] != undefined) {
				a_entryObject.material = Material.DEATHBRAND;
				a_entryObject.materialDisplay = "$Deathbrand";
			}
		
		} else if (a_entryObject.keywords["WeapMaterialDraugr"] != undefined) {
			a_entryObject.material = Material.DRAGUR;
			a_entryObject.materialDisplay = "$Dragur";
		
		} else if (a_entryObject.keywords["WeapMaterialDraugrHoned"] != undefined) {
			a_entryObject.material = Material.DRAGURHONED;
			a_entryObject.materialDisplay = "$Dragur Honed";
		
		} else if (a_entryObject.keywords["WeapMaterialFalmer"] != undefined) {
			a_entryObject.material = Material.FALMER;
			a_entryObject.materialDisplay = "$Falmer";
		
		} else if (a_entryObject.keywords["WeapMaterialFalmerHoned"] != undefined) {
			a_entryObject.material = Material.FALMERHONED;
			a_entryObject.materialDisplay = "$Falmer Honed";
		
		} else if (a_entryObject.keywords["WeapMaterialSilver"] != undefined) {
			a_entryObject.material = Material.SILVER;
			a_entryObject.materialDisplay = "$Silver";
		
		} else if (a_entryObject.keywords["WeapMaterialWood"] != undefined) {
			a_entryObject.material = Material.WOOD;
			a_entryObject.materialDisplay = "$Wood";
		}
	}

	private function processWeaponType(a_entryObject: Object): Void
	{
		a_entryObject.subType = Weapon.OTHER;
		a_entryObject.subTypeDisplay = "$Weapon";

		switch (a_entryObject.weaponType) {
			case Weapon.EQUIPTYPE_HANDTOHANDMELEE:
			case Weapon.EQUIPTYPE_H2H:
				a_entryObject.subType = Weapon.TYPE_MELEE;
				a_entryObject.subTypeDisplay = "$Melee";
				break;

			case Weapon.EQUIPTYPE_ONEHANDSWORD:
			case Weapon.EQUIPTYPE_1HS:
				a_entryObject.subType = Weapon.TYPE_SWORD;
				a_entryObject.subTypeDisplay = "$Sword";
				break;

			case Weapon.EQUIPTYPE_ONEHANDDAGGER:
			case Weapon.EQUIPTYPE_1HD:
				a_entryObject.subType = Weapon.TYPE_DAGGER;
				a_entryObject.subTypeDisplay = "$Dagger";
				break;

			case Weapon.EQUIPTYPE_ONEHANDAXE:
			case Weapon.EQUIPTYPE_1HA:
				a_entryObject.subType = Weapon.TYPE_WARAXE;
				a_entryObject.subTypeDisplay = "$War Axe";
				break;

			case Weapon.EQUIPTYPE_ONEHANDMACE:
			case Weapon.EQUIPTYPE_1HM:
				a_entryObject.subType = Weapon.TYPE_MACE;
				a_entryObject.subTypeDisplay = "$Mace";
				break;

			case Weapon.EQUIPTYPE_TWOHANDSWORD:
			case Weapon.EQUIPTYPE_2HS:
				a_entryObject.subType = Weapon.TYPE_GREATSWORD;
				a_entryObject.subTypeDisplay = "$Greatsword";
				break;

			case Weapon.EQUIPTYPE_TWOHANDAXE:
			case Weapon.EQUIPTYPE_2HA:
				a_entryObject.subType = Weapon.TYPE_BATTLEAXE;
				a_entryObject.subTypeDisplay = "$Battleaxe";

				if (a_entryObject.keywords != undefined && a_entryObject.keywords["WeapTypeWarhammer"] != undefined) {
					a_entryObject.subType = Weapon.TYPE_WARHAMMER;
					a_entryObject.subTypeDisplay = "$Warhammer";
				}
				break;

			case Weapon.EQUIPTYPE_BOW:
			case Weapon.EQUIPTYPE_BOW2:
				a_entryObject.subType = Weapon.TYPE_BOW;
				a_entryObject.subTypeDisplay = "$Bow";
				break;

			case Weapon.EQUIPTYPE_STAFF:
			case Weapon.EQUIPTYPE_STAFF2:
				a_entryObject.subType = Weapon.TYPE_STAFF;
				a_entryObject.subTypeDisplay = "$Staff";
				break;

			case Weapon.EQUIPTYPE_CROSSBOW:
			case Weapon.EQUIPTYPE_CBOW:
				a_entryObject.subType = Weapon.TYPE_CROSSBOW;
				a_entryObject.subTypeDisplay = "$Crossbow";
				break;
		}
	}


	private function processArmorPartMask(a_entryObject: Object): Void
	{
		if (a_entryObject.partMask == undefined)
			return;

		// Sets subType as the most important bitmask index.
		for (var i = 0; i < Armor.PARTMASK_PRECEDENCE.length; i++) {
			if (a_entryObject.partMask & Armor.PARTMASK_PRECEDENCE[i]) {
				a_entryObject.mainPartMask = Armor.PARTMASK_PRECEDENCE[i];
				break;
			}
		}

		if (a_entryObject.mainPartMask == undefined)
			return;

		switch (a_entryObject.mainPartMask) {
			case Armor.PARTMASK_HEAD:
				a_entryObject.subType = Armor.EQUIPLOCATION_HEAD;
				a_entryObject.subTypeDisplay = "$Head";
				break;
			case Armor.PARTMASK_HAIR:
				a_entryObject.subType = Armor.EQUIPLOCATION_HAIR;
				a_entryObject.subTypeDisplay = "$Head";
				break;
			case Armor.PARTMASK_LONGHAIR:
				a_entryObject.subType = Armor.EQUIPLOCATION_LONGHAIR;
				a_entryObject.subTypeDisplay = "$Head";
				break;

			case Armor.PARTMASK_BODY:
				a_entryObject.subType = Armor.EQUIPLOCATION_BODY;
				a_entryObject.subTypeDisplay = "$Body";
				break;

			case Armor.PARTMASK_HANDS:
				a_entryObject.subType = Armor.EQUIPLOCATION_HANDS;
				a_entryObject.subTypeDisplay = "$Hands";
				break;

			case Armor.PARTMASK_FOREARMS:
				a_entryObject.subType = Armor.EQUIPLOCATION_FOREARMS;
				a_entryObject.subTypeDisplay = "$Forearms";
				break;

			case Armor.PARTMASK_AMULET:
				a_entryObject.subType = Armor.EQUIPLOCATION_AMULET;
				a_entryObject.subTypeDisplay = "$Amulet";
				break;

			case Armor.PARTMASK_RING:
				a_entryObject.subType = Armor.EQUIPLOCATION_RING;
				a_entryObject.subTypeDisplay = "$Ring";
				break;

			case Armor.PARTMASK_FEET:
				a_entryObject.subType = Armor.EQUIPLOCATION_FEET;
				a_entryObject.subTypeDisplay = "$Feet";
				break;

			case Armor.PARTMASK_CALVES:
				a_entryObject.subType = Armor.EQUIPLOCATION_CALVES;
				a_entryObject.subTypeDisplay = "$Calves";
				break;

			case Armor.PARTMASK_SHIELD:
				a_entryObject.subType = Armor.EQUIPLOCATION_SHIELD;
				a_entryObject.subTypeDisplay = "$Shield";
				break;

			case Armor.PARTMASK_CIRCLET:
				a_entryObject.subType = Armor.EQUIPLOCATION_CIRCLET;
				a_entryObject.subTypeDisplay = "$Circlet";
				break;

			case Armor.PARTMASK_EARS:
				a_entryObject.subType = Armor.EQUIPLOCATION_EARS;
				a_entryObject.subTypeDisplay = "$Ears";
				break;

			case Armor.PARTMASK_TAIL:
				a_entryObject.subType = Armor.EQUIPLOCATION_TAIL;
				a_entryObject.subTypeDisplay = "$Tail";
				break;

			default:
				a_entryObject.subType = a_entryObject.mainPartMask;
				break;
		}
	}

	private function processArmorOther(a_entryObject): Void
	{
		if (a_entryObject.weightClass != Armor.OTHER)
			return;

		switch(a_entryObject.mainPartMask) {
			case Armor.PARTMASK_HEAD:
			case Armor.PARTMASK_HAIR:
			case Armor.PARTMASK_LONGHAIR:
			case Armor.PARTMASK_BODY:
			case Armor.PARTMASK_HANDS:
			case Armor.PARTMASK_FOREARMS:
			case Armor.PARTMASK_FEET:
			case Armor.PARTMASK_CALVES:
			case Armor.PARTMASK_SHIELD:
			case Armor.PARTMASK_TAIL:
				a_entryObject.weightClass = Armor.WEIGHTCLASS_CLOTHING;
				a_entryObject.weightClassDisplay = "$Clothing";
				break;

			case Armor.PARTMASK_AMULET:
			case Armor.PARTMASK_RING:
			case Armor.PARTMASK_CIRCLET:
			case Armor.PARTMASK_EARS:
				a_entryObject.weightClass = Armor.WEIGHTCLASS_JEWELRY;
				a_entryObject.weightClassDisplay = "$Jewelry";
				break;
		}
	}

	private function processBookType(a_entryObject: Object): Void
	{
		a_entryObject.subType = Item.OTHER;
		a_entryObject.subTypeDisplay = "$Book";
		
		if (a_entryObject.bookType & Item.BOOKFLAG_NOTE) {
			a_entryObject.subType = Item.BOOK_NOTE;
			a_entryObject.subTypeDisplay = "$Note";
		}

		if (a_entryObject.keywords == undefined)
			return;

		if (a_entryObject.keywords["VendorItemRecipe"] != undefined) {
			a_entryObject.subType = Item.BOOK_RECIPE;
			a_entryObject.subTypeDisplay = "$Recipe";
		} else if (a_entryObject.keywords["VendorItemSpellTome"] != undefined) {
			a_entryObject.subType = Item.BOOK_SPELLTOME;
			a_entryObject.subTypeDisplay = "$Spell Tome";
		}
	}

	private function processAmmoType(a_entryObject: Object): Void
	{
		if ((a_entryObject.flags & Weapon.AMMOFLAG_NONBOLT) != 0) {
			a_entryObject.subType = Weapon.AMMO_ARROW;
			a_entryObject.subTypeDisplay = "$Arrow";
		} else {
			a_entryObject.subType = Weapon.AMMO_BOLT;
			a_entryObject.subTypeDisplay = "$Bolt";
		}
	}

	private function processKeyType(a_entryObject: Object): Void
	{
		a_entryObject.subTypeDisplay = "$Key";

		if (a_entryObject.value <= 0) {
			a_entryObject.value = undefined;
			a_entryObject.valueDisplay = "-";
		}

		if (a_entryObject.weight <= 0) {
			a_entryObject.weight = undefined;
			a_entryObject.weightDisplay = "-";
		}
	}

	private function processPotionType(a_entryObject: Object): Void
	{
		a_entryObject.subType = Item.POTION_POTION;
		a_entryObject.subTypeDisplay = "$Potion";

		if ((a_entryObject.flags & Item.ALCHFLAG_FOOD) != 0) {
			a_entryObject.subType = Item.POTION_FOOD;
			a_entryObject.subTypeDisplay = "$Food";

			if (a_entryObject.type == Inventory.ICT_POTION) {
				a_entryObject.subType = Item.POTION_DRINK;
				a_entryObject.subTypeDisplay = "$Drink";
			}
		} else if ((a_entryObject.flags & Item.ALCHFLAG_POISON) != 0) {
			a_entryObject.subType = Item.POTION_POISON;
			a_entryObject.subTypeDisplay = "$Poison";
		} else {
			switch (a_entryObject.actorValue) {
				case Actor.ACTORVALUE_HEALTH:
					a_entryObject.subType = Item.POTION_HEALTH;
					a_entryObject.subTypeDisplay = "$Health";
					break;
				case Actor.ACTORVALUE_MAGICKA:
					a_entryObject.subType = Item.POTION_MAGICKA;
					a_entryObject.subTypeDisplay = "$Magicka";
					break;
				case Actor.ACTORVALUE_STAMINA:
					a_entryObject.subType = Item.POTION_STAMINA;
					a_entryObject.subTypeDisplay = "$Stamina";
					break;

				case Actor.ACTORVALUE_HEALRATE:
					a_entryObject.subType = Item.POTION_HEALRATE;
					a_entryObject.subTypeDisplay = "$Health";
					break;
				case Actor.ACTORVALUE_MAGICKARATE:
					a_entryObject.subType = Item.POTION_MAGICKARATE;
					a_entryObject.subTypeDisplay = "$Magicka";
					break;
				case Actor.ACTORVALUE_STAMINARATE:
					a_entryObject.subType = Item.POTION_STAMINARATE;
					a_entryObject.subTypeDisplay = "$Stamina";
					break;

				case Actor.ACTORVALUE_HEALRATEMULT:
					a_entryObject.subType = Item.POTION_HEALRATEMULT;
					a_entryObject.subTypeDisplay = "$Health";
					break;
				case Actor.ACTORVALUE_MAGICKARATEMULT:
					a_entryObject.subType = Item.POTION_MAGICKARATEMULT;
					a_entryObject.subTypeDisplay = "$Magicka";
					break;
				case Actor.ACTORVALUE_STAMINARATEMULT:
					a_entryObject.subType = Item.POTION_STAMINARATEMULT;
					a_entryObject.subTypeDisplay = "$Stamina";
					break;

				case Actor.ACTORVALUE_FIRERESIST:
					a_entryObject.subType = Item.POTION_FIRERESIST;
					break;

				case Actor.ACTORVALUE_ELECTRICRESIST:
					a_entryObject.subType = Item.POTION_SHOCKRESIST;
					break;

				case Actor.ACTORVALUE_FROSTRESIST:
					a_entryObject.subType = Item.POTION_FROSTRESIST;
					break;
			}
		}
	}

	private function processSoulGemType(a_entryObject: Object): Void
	{
		a_entryObject.subType = Item.OTHER;
		a_entryObject.subTypeDisplay = "$Soul Gem";

		// Ignores soulgems that have a size of None
		if (a_entryObject.gemSize != undefined && a_entryObject.gemSize != Item.SOULGEM_NONE)
			a_entryObject.subType = a_entryObject.gemSize;
	}

	private function processSoulGemStatus(a_entryObject: Object): Void
	{
		if (a_entryObject.gemSize == undefined || a_entryObject.soulSize == undefined || a_entryObject.soulSize == Item.SOULGEM_NONE)
			a_entryObject.status = Item.SOULGEMSTATUS_EMPTY;
		else if (a_entryObject.soulSize >= a_entryObject.gemSize)
			a_entryObject.status = Item.SOULGEMSTATUS_FULL;
		else
			a_entryObject.status = Item.SOULGEMSTATUS_PARTIAL;
	}

	private function processMiscType(a_entryObject: Object): Void
	{
		a_entryObject.subType = Item.OTHER;
		a_entryObject.subTypeDisplay = "$Misc";

		if (a_entryObject.keywords == undefined)
			return;

		if (a_entryObject.keywords["BYOHAdoptionClothesKeyword"] != undefined) {
			a_entryObject.subType = Item.MISC_CHILDRENSCLOTHES;
			a_entryObject.subTypeDisplay = "$Childrens Clothes";

		} else if (a_entryObject.keywords["BYOHAdoptionToyKeyword"] != undefined) {
			a_entryObject.subType = Item.MISC_TOY;
			a_entryObject.subTypeDisplay = "$Toy";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryWeaponRacks"] != undefined) {
			a_entryObject.subType = Item.MISC_WEAPONRACK;
			a_entryObject.subTypeDisplay = "$Weapon Rack";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryShelf"] != undefined) {
			a_entryObject.subType = Item.MISC_SHELF;
			a_entryObject.subTypeDisplay = "$Shelf";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryFurniture"] != undefined) {
			a_entryObject.subType = Item.MISC_FURNITURE;
			a_entryObject.subTypeDisplay = "$Furniture";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryExterior"] != undefined) {
			a_entryObject.subType = Item.MISC_EXTERIOR;
			a_entryObject.subTypeDisplay = "$Exterior Furniture";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryContainers"] != undefined) {
			a_entryObject.subType = Item.MISC_CONTAINER;
			a_entryObject.subTypeDisplay = "$Container";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategoryBuilding"] != undefined) {
			a_entryObject.subType = Item.MISC_HOUSEPART;
			a_entryObject.subTypeDisplay = "$House Part";

		} else if (a_entryObject.keywords["BYOHHouseCraftingCategorySmithing"] != undefined) {
			a_entryObject.subType = Item.MISC_FASTENER;
			a_entryObject.subTypeDisplay = "$Fastener";

		} else if (a_entryObject.keywords["VendorItemDaedricArtifact"] != undefined) {
			a_entryObject.subType = Item.MISC_ARTIFACT;
			a_entryObject.subTypeDisplay = "$Artifact";

		} else if (a_entryObject.keywords["VendorItemGem"] != undefined) {
			a_entryObject.subType = Item.MISC_GEM;
			a_entryObject.subTypeDisplay = "$Gem";

		} else if (a_entryObject.keywords["VendorItemAnimalHide"] != undefined) {
			a_entryObject.subType = Item.MISC_HIDE;
			a_entryObject.subTypeDisplay = "$Hide";

		} else if (a_entryObject.keywords["VendorItemTool"] != undefined) {
			a_entryObject.subType = Item.MISC_TOOL;
			a_entryObject.subTypeDisplay = "$Tool";

		} else if (a_entryObject.keywords["VendorItemAnimalPart"] != undefined) {
			a_entryObject.subType = Item.MISC_REMAINS;
			a_entryObject.subTypeDisplay = "$Remains";

		} else if (a_entryObject.keywords["VendorItemOreIngot"] != undefined) {
			a_entryObject.subType = Item.MISC_INGOT;
			a_entryObject.subTypeDisplay = "$Ingot";

		} else if (a_entryObject.keywords["VendorItemClutter"] != undefined) {
			a_entryObject.subType = Item.MISC_CLUTTER;
			a_entryObject.subTypeDisplay = "$Clutter";

		} else if (a_entryObject.keywords["VendorItemFirewood"] != undefined) {
			a_entryObject.subType = Item.MISC_FIREWOOD;
			a_entryObject.subTypeDisplay = "$Firewood";
		}
	}
}


// skyui.util.Debug.dump(a_entryObject["text"], a_entryObject);