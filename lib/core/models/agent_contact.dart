class AgentContact {
  final String nameKey;
  final String phone;
  final String displayNameOverride;
  final String honorific;
  final String email;
  final String instagram;
  final String avatarUrl;

  const AgentContact({
    String? nameKey,
    String? key,
    String? phone,
    String? phoneNumber,
    String displayName = '',
    this.honorific = 'Pak',
    this.email = '',
    this.instagram = '',
    this.avatarUrl = '',
  })  : nameKey = nameKey ?? key ?? '',
        phone = phone ?? phoneNumber ?? '',
        displayNameOverride = displayName;

  String get key => nameKey;
  String get phoneNumber => phone;

  String get displayName => displayNameOverride.trim().isNotEmpty
      ? displayNameOverride.trim()
      : capitalizeAgentName(nameKey);

  String get formattedPhoneDisplay {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 10) {
      final p1 = clean.substring(0, 4);
      final p2 = clean.substring(4, 8);
      final p3 = clean.substring(8);
      return '$p1-$p2-$p3';
    }
    return phone;
  }

  String get formattedInstagram {
    if (instagram.trim().isEmpty) return '';
    final ig = instagram.trim();
    return ig.startsWith('@') ? ig : '@$ig';
  }

  Map<String, dynamic> toJson() => {
        'key': nameKey,
        'nameKey': nameKey,
        'phone': phone,
        'phoneNumber': phone,
        'displayName': displayName,
        'honorific': honorific,
        'email': email,
        'instagram': instagram,
        'avatarUrl': avatarUrl,
      };

  factory AgentContact.fromJson(Map<String, dynamic> json) => AgentContact(
        nameKey: (json['nameKey'] ?? json['key'] ?? '')
            .toString()
            .trim()
            .toLowerCase(),
        phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString().trim(),
        displayName: (json['displayName'] ?? '').toString().trim(),
        honorific: (json['honorific'] ?? 'Pak').toString().trim(),
        email: (json['email'] ?? '').toString().trim(),
        instagram: (json['instagram'] ?? '').toString().trim(),
        avatarUrl: (json['avatarUrl'] ?? '').toString().trim(),
      );

  AgentContact copyWith({
    String? nameKey,
    String? key,
    String? phone,
    String? phoneNumber,
    String? displayName,
    String? honorific,
    String? email,
    String? instagram,
    String? avatarUrl,
  }) =>
      AgentContact(
        nameKey: nameKey ?? key ?? this.nameKey,
        phone: phone ?? phoneNumber ?? this.phone,
        displayName: displayName ?? displayNameOverride,
        honorific: honorific ?? this.honorific,
        email: email ?? this.email,
        instagram: instagram ?? this.instagram,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

const List<AgentContact> kDefaultAgentContacts = kDefaultAgentContactList;

const List<AgentContact> kDefaultAgentContactList = [
  AgentContact(
    nameKey: 'donny',
    displayName: 'Pak Donny',
    honorific: 'Pak',
    phone: '087877777677',
    email: 'donny.raywhite@yahoo.com',
    instagram: 'donny.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/49c8a2a7b029496da370b2d445857ce5.jpg',
  ),
  AgentContact(
    nameKey: 'agung',
    displayName: 'Pak Agung',
    honorific: 'Pak',
    phone: '081808801688',
    email: 'agung.rwcipete@gmail.com',
    instagram: 'agungrwcipete',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/76df4404fcde4c45894f190ea993fe28.jpg',
  ),
  AgentContact(
    nameKey: 'bayu',
    displayName: 'Pak Bayu',
    honorific: 'Pak',
    phone: '081287222799',
    email: 'bayu.raywhite@gmail.com',
    instagram: 'bayu.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/ec540f8efa2b48dcb16a05d3c600e089.jpg',
  ),
  AgentContact(
    nameKey: 'dian',
    displayName: 'Bu Dian',
    honorific: 'Bu',
    phone: '08161338093',
    email: 'dians.raywhite@gmail.com',
    instagram: 'south.jakarta.home',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/9bac3dfc5d3743abaf283feb2ac66837.jpg',
  ),
  AgentContact(
    nameKey: 'dini',
    displayName: 'Bu Dini',
    honorific: 'Bu',
    phone: '081282331997',
    email: 'diniwiryandoko@gmail.com',
    instagram: 'diniraywhitecipete',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/87a6095c698846649a240cce4e691540.jpg',
  ),
  AgentContact(
    nameKey: 'dutta',
    displayName: 'Bu Dutta',
    honorific: 'Bu',
    phone: '081381564918',
    email: 'duta.raywhite@gmail.com',
    instagram: 'duttaraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/11b73e232d75482fbdfe62cd2b29fc49.jpg',
  ),
  AgentContact(
    nameKey: 'duta',
    displayName: 'Bu Duta',
    honorific: 'Bu',
    phone: '081381564918',
    email: 'duta.raywhite@gmail.com',
    instagram: 'duttaraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/11b73e232d75482fbdfe62cd2b29fc49.jpg',
  ),
  AgentContact(
    nameKey: 'ifa',
    displayName: 'Bu Ifa',
    honorific: 'Bu',
    phone: '087885588897',
    email: 'ifadebrianti.raywhite@gmail.com',
    instagram: 'ifa.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/5174239cff7c4ebea82af33cfde98741.png',
  ),
  AgentContact(
    nameKey: 'ike',
    displayName: 'Bu Ike',
    honorific: 'Bu',
    phone: '081808361616',
    email: 'ikejuliastuti@gmail.com',
    instagram: 'raywhite_ike',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/83a185c1ac224fafb0222c8fbbcbf206.jpg',
  ),
  AgentContact(
    nameKey: 'ilham',
    displayName: 'Pak Ilham',
    honorific: 'Pak',
    phone: '08561103735',
    email: 'ilham.rwcipete@gmail.com',
    instagram: 'ilhamsraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/eed74efba0244fa684931eec1fde6d25.jpg',
  ),
  AgentContact(
    nameKey: 'imelda',
    displayName: 'Bu Imelda',
    honorific: 'Bu',
    phone: '082177888816',
    email: 'imelda.djuarta@yahoo.com',
    instagram: 'raywhite_imelda_djuarta',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/bf4d3155941c4dfd9f2b11c6af769185.jpg',
  ),
  AgentContact(
    nameKey: 'iskandar',
    displayName: 'Pak Iskandar',
    honorific: 'Pak',
    phone: '08111823456',
    email: 'iskandar.raywhite@gmail.com',
    instagram: 'iskandar.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/08282f939a1345fc8da6f430d3a55c9c.png',
  ),
  AgentContact(
    nameKey: 'michael',
    displayName: 'Pak Michael',
    honorific: 'Pak',
    phone: '081286960275',
    email: 'michael.rwcipete@gmail.com',
    instagram: 'michael.raywhite',
    avatarUrl: '',
  ),
  AgentContact(
    nameKey: 'remmy',
    displayName: 'Pak Remmy',
    honorific: 'Pak',
    phone: '081286960275',
    email: 'michael.rwcipete@gmail.com',
    instagram: 'michael.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/01fe33087b2c46deb3d0c118892a830e.jpg',
  ),
  AgentContact(
    nameKey: 'resmi',
    displayName: 'Bu Resmi',
    honorific: 'Bu',
    phone: '081380620625',
    email: 'resmi.raywhite@gmail.com',
    instagram: '',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/d0f6229f97b44b5391a670a49b491976.jpg',
  ),
  AgentContact(
    nameKey: 'sam',
    displayName: 'Pak Sam',
    honorific: 'Pak',
    phone: '081298070006',
    email: 'sam.rwcipete@gmail.com',
    instagram: 'samsuperagent',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/b56e268949314c07836bdc7c147b6097.png',
  ),
  AgentContact(
    nameKey: 'santiaji',
    displayName: 'Pak Santiaji',
    honorific: 'Pak',
    phone: '085219698553',
    email: 'ajisantiaji88@gmail.com',
    instagram: '',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/fa937a9a751f47f185d1f5f6751992a8.jpg',
  ),
  AgentContact(
    nameKey: 'vincent',
    displayName: 'Pak Vincent',
    honorific: 'Pak',
    phone: '081212892189',
    email: 'vincent@raywhitecipete.net',
    instagram: 'vincentbrata',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/77f71d4c791a430a9064cbee1a095441.jpg',
  ),
  AgentContact(
    nameKey: 'yayan',
    displayName: 'Pak Yayan',
    honorific: 'Pak',
    phone: '082114005670',
    email: 'yayanhb2005@gmail.com',
    instagram: 'raywhite_yayan',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/6de32af7a6ae4661ad21dd78f23fa8da.jpg',
  ),
  AgentContact(
    nameKey: 'haryadi',
    displayName: 'Pak Haryadi',
    honorific: 'Pak',
    phone: '08111373777',
    email: 'haryadi.raywhite@gmail.com',
    instagram: 'Haryadi.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/8e79bb1daff74ba587f0eadf26c9b399.png',
  ),
  AgentContact(
    nameKey: 'rony',
    displayName: 'Pak Rony',
    honorific: 'Pak',
    phone: '0811190046',
    email: 'rony.raywhitecipete@gmail.com',
    instagram: 'rony.raywhitecipete',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/8fdc71d7862e4d7ba439058003ea91fc.jpg',
  ),
  AgentContact(
    nameKey: 'indah',
    displayName: 'Bu Indah',
    honorific: 'Bu',
    phone: '082125120021',
    email: 'indah.raywhitecipete@gmail.com',
    instagram: 'indah.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/0cce2d67e6a4463a877d9a5d537db1ac.jpg',
  ),
  AgentContact(
    nameKey: 'dasep',
    displayName: 'Pak Dasep',
    honorific: 'Pak',
    phone: '0818348046',
    email: 'dasep.raywhite@gmail.com',
    instagram: 'dasepraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/646f72049451468f8b490cb95ea6ee70.jpg',
  ),
  AgentContact(
    nameKey: 'ruby',
    displayName: 'Bu Ruby',
    honorific: 'Bu',
    phone: '085779153217',
    email: 'ruby.raywhite@gmail.com',
    instagram: 'ruby.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/018e09bb35ba43139740c8c884d642cb.jpg',
  ),
  AgentContact(
    nameKey: 'aii dyana',
    displayName: 'Bu Aii Dyana',
    honorific: 'Bu',
    phone: '081295951179',
    email: 'aiidyana.raywhite@gmail.com',
    instagram: 'aiiraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/a53a253345c040439738eb76a499b1c4.jpg',
  ),
  AgentContact(
    nameKey: 'dyana',
    displayName: 'Bu Dyana',
    honorific: 'Bu',
    phone: '081295951179',
    email: 'aiidyana.raywhite@gmail.com',
    instagram: 'aiiraywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/a53a253345c040439738eb76a499b1c4.jpg',
  ),
  AgentContact(
    nameKey: 'dedie',
    displayName: 'Pak Dedie',
    honorific: 'Pak',
    phone: '082198909493',
    email: 'dedie.rwc@gmail.com',
    instagram: 'dedie.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/78637630471c44ba8bdb1a0c2b9e3efa.jpg',
  ),
  AgentContact(
    nameKey: 'ayu',
    displayName: 'Bu Ayu',
    honorific: 'Bu',
    phone: '087880476149',
    email: 'ayu.raywhite@gmail.com',
    instagram: 'ayukusumarwc',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/b9c2d6de3e2e4d338284fe03b44e3a74.png',
  ),
  AgentContact(
    nameKey: 'dhenis',
    displayName: 'Pak Dhenis',
    honorific: 'Pak',
    phone: '08567773081',
    email: 'dhenisemanuelraywhite@gmail.com',
    instagram: 'rumahbydhenis',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/eef9c4899573431cb48f95375b0473e8.jpg',
  ),
  AgentContact(
    nameKey: 'zulkifli',
    displayName: 'Pak Zulkifli',
    honorific: 'Pak',
    phone: '081230016702',
    email: 'zulkifli.raywhite@gmail.com',
    instagram: 'zulkifli_rwc',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/10c0124d11784da5ac97adbbc9389f1d.png',
  ),
  AgentContact(
    nameKey: 'muljadi',
    displayName: 'Pak Muljadi',
    honorific: 'Pak',
    phone: '0811108308',
    email: 'muljadi.raywhite@yahoo.com',
    instagram: '',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/000d0049606e4c89b84772191e14653e.png',
  ),
  AgentContact(
    nameKey: 'andika',
    displayName: 'Pak Andika',
    honorific: 'Pak',
    phone: '081932899091',
    email: 'tan.andika@gmail.com',
    instagram: 'andika.rwc',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/73ef1fad95914d1a8f4549956aeedb0e.png',
  ),
  AgentContact(
    nameKey: 'mari',
    displayName: 'Bu Mari',
    honorific: 'Bu',
    phone: '08118087908',
    email: 'marihariadi.raywhite@gmail.com',
    instagram: 'mari.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/c6345748eb234604b17f76d586d983e0.jpg',
  ),
  AgentContact(
    nameKey: 'amelia',
    displayName: 'Bu Amelia',
    honorific: 'Bu',
    phone: '087784882233',
    email: 'amelia.raywhitecipete@gmail.com',
    instagram: 'aimeeworks.property',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/0826299b862b402ab26a998d64fcb823.png',
  ),
  AgentContact(
    nameKey: 'hilda',
    displayName: 'Bu Hilda',
    honorific: 'Bu',
    phone: '0817216161',
    email: 'hilda.raywhite@gmail.com',
    instagram: 'hilda.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/a3847789d43e4a089f2b960e4d644fb9.png',
  ),
  AgentContact(
    nameKey: 'desy',
    displayName: 'Bu Desy',
    honorific: 'Bu',
    phone: '081284001033',
    email: 'desy.raywhite@gmail.com',
    instagram: 'desy.raywhite',
    avatarUrl: '',
  ),
  AgentContact(
    nameKey: 'briand',
    displayName: 'Pak Briand',
    honorific: 'Pak',
    phone: '08176676276',
    email: 'briandrwc@gmail.com',
    instagram: 'briandproperty',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/e7be7e7020494be9b88a1cb4d48d3a9e.jpg',
  ),
  AgentContact(
    nameKey: 'rika',
    displayName: 'Bu Rika',
    honorific: 'Bu',
    phone: '081218280096',
    email: 'rikaraywhite@yahoo.com',
    instagram: 'rikaraywhite1',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/635af76844b94cd2acd17594aa5e6395.jpg',
  ),
  AgentContact(
    nameKey: 'meisi',
    displayName: 'Bu Meisi',
    honorific: 'Bu',
    phone: '0817855005',
    email: 'meisiraywhite@gmail.com',
    instagram: 'meisi.raywhite',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/d40e1d5178fd46278e6415a2b7f6ecd9.jpg',
  ),
  AgentContact(
    nameKey: 'yuma',
    displayName: 'Bu Yuma',
    honorific: 'Bu',
    phone: '08118585137',
    email: 'yumaray.raywhite@gmail.com',
    instagram: 'yuma_ray_cht_ci',
    avatarUrl:
        'https://s3-ap-southeast-1.amazonaws.com/hhproperty/MarketingAgent/a706d7d815874f94bffb8e21156b2d62.jpeg',
  ),
  AgentContact(
    nameKey: 'utomo',
    displayName: 'Pak Utomo',
    honorific: 'Pak',
    phone: '081219759295',
    email: '',
    instagram: '',
    avatarUrl: '',
  ),
];

List<AgentContact> globalCustomAgentContacts = [];

String capitalizeAgentName(String name) {
  if (name.trim().isEmpty) return '';
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

AgentContact? findAgentContact(
  String meName, {
  List<AgentContact>? customAgents,
  List<AgentContact>? customList,
}) {
  final cleanName = meName.trim().toLowerCase();
  if (cleanName.isEmpty) return null;

  final custom = customAgents ?? customList;
  final listToSearch = (custom != null && custom.isNotEmpty)
      ? [...custom, ...kDefaultAgentContactList]
      : (globalCustomAgentContacts.isNotEmpty
          ? [...globalCustomAgentContacts, ...kDefaultAgentContactList]
          : kDefaultAgentContactList);

  for (final c in listToSearch) {
    if (c.nameKey == cleanName) return c;
  }

  final words = cleanName.split(RegExp(r'\s+'));
  for (final c in listToSearch) {
    if (words.contains(c.nameKey)) return c;
  }

  for (final c in listToSearch) {
    final isOverlap = (c.nameKey == 'ayu' && cleanName.contains('bayu')) ||
        (c.nameKey == 'bayu' &&
            cleanName.contains('ayu') &&
            !cleanName.contains('bayu')) ||
        (c.nameKey == 'bayu' && cleanName.contains('kebayoran'));
    if (isOverlap) continue;
    if (cleanName.contains(c.nameKey) || c.nameKey.contains(cleanName)) {
      return c;
    }
  }
  return null;
}

List<String> parseMultipleAgentNames(String rawNames) {
  if (rawNames.trim().isEmpty) return [];
  final normalized = rawNames
      .replaceAll(' dan ', '/')
      .replaceAll(' Dan ', '/')
      .replaceAll(' DAN ', '/')
      .replaceAll(' & ', '/')
      .replaceAll(',', '/')
      .replaceAll(';', '/');
  return normalized
      .split('/')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

String formatAgentName(String scrapedName) {
  final parts = parseMultipleAgentNames(scrapedName);
  if (parts.isEmpty) return capitalizeAgentName(scrapedName);
  return parts.map((p) {
    final contact = findAgentContact(p);
    return contact != null
        ? capitalizeAgentName(contact.nameKey)
        : capitalizeAgentName(p);
  }).join(' / ');
}

String getAgentPhoneByName(String meName) {
  final firstPart = parseMultipleAgentNames(meName).firstOrNull ?? meName;
  return findAgentContact(firstPart)?.phone ?? '';
}

String getAgentEmailByName(String meName) {
  final firstPart = parseMultipleAgentNames(meName).firstOrNull ?? meName;
  return findAgentContact(firstPart)?.email ?? '';
}

String getAgentInstagramByName(String meName) {
  final firstPart = parseMultipleAgentNames(meName).firstOrNull ?? meName;
  return findAgentContact(firstPart)?.formattedInstagram ?? '';
}

String getAgentAvatarByName(String meName) {
  final firstPart = parseMultipleAgentNames(meName).firstOrNull ?? meName;
  return findAgentContact(firstPart)?.avatarUrl ?? '';
}

bool isStatusTagText(String text) {
  final lower = text.trim().toLowerCase();
  return lower == 'ig' ||
      lower == 'hot property' ||
      lower == 'foto ulang' ||
      lower == 'done' ||
      lower == 'pending';
}

String? extractJudulFromNotes(String notes) {
  if (notes.trim().isEmpty) return null;
  final bracketMatch =
      RegExp(r'\[Judul:\s*([^\]]+)\]', caseSensitive: false).firstMatch(notes);
  if (bracketMatch != null) {
    final extracted = bracketMatch.group(1)?.trim() ?? '';
    if (extracted.isNotEmpty) return extracted;
  }

  final lower = notes.toLowerCase();
  final idx = lower.indexOf('judul');
  if (idx == -1) return null;

  final afterJudul =
      notes.substring(idx + 5).replaceFirst(RegExp(r'^[:=\-\s]+'), '');
  if (afterJudul.isEmpty) return null;

  final lines = afterJudul
      .split(RegExp(r'[\n;]'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;

  final firstLine = lines.first;
  String titlePart = firstLine;
  if (firstLine.contains(',')) {
    final parts = firstLine.split(',');
    final firstPart = parts[0].trim();
    final secondPartLower =
        parts.length > 1 ? parts[1].toLowerCase().trim() : '';
    if (secondPartLower.contains('edit') ||
        secondPartLower.contains('foto') ||
        secondPartLower.contains('lt') ||
        secondPartLower.contains('lb') ||
        secondPartLower.contains('tag') ||
        secondPartLower.contains('status') ||
        secondPartLower.contains('correct') ||
        secondPartLower.contains('perspective') ||
        secondPartLower.contains('remove') ||
        isStatusTagText(secondPartLower)) {
      titlePart = firstPart;
    }
  }
  return (titlePart.isNotEmpty && !isStatusTagText(titlePart))
      ? titlePart
      : null;
}
