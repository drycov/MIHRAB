enum Dhikr {
  tasbih('Субханаллах','سُبْحَانَ اللَّهِ'),
  tahmid('Альхамдулиллях','الْحَمْدُ لِلَّهِ'),
  takbir('Аллаху акбар','اللَّهُ أَكْبَرُ'),
  istighfar('Астагфируллах','أَسْتَغْفِرُ اللَّهَ'),
  free('Свободный счёт','');
  const Dhikr(this.label,this.arabic);
  final String label,arabic;
}

class TasbihSession {
  const TasbihSession(this.dhikr,this.target,this.completedAt);
  final Dhikr dhikr;
  final int target;
  final DateTime completedAt;
  Map<String,dynamic> toJson()=>{'dhikr':dhikr.name,'target':target,'completedAt':completedAt.toUtc().toIso8601String()};
  factory TasbihSession.fromJson(Map<String,dynamic> j){
    final target=j['target'] as int;
    if(target<1||target>9999)throw const FormatException('Invalid target');
    return TasbihSession(Dhikr.values.byName(j['dhikr'] as String),target,DateTime.parse(j['completedAt'] as String).toUtc());
  }
}

class TasbihState {
  const TasbihState({this.dhikr=Dhikr.tasbih,this.target=33,this.count=0,this.haptic=true,this.history=const []});
  final Dhikr dhikr;
  final int target,count;
  final bool haptic;
  final List<TasbihSession> history;
  bool get complete=>count==target;
  TasbihState increment(DateTime now){
    if(complete)return this;
    final next=count+1;
    return TasbihState(dhikr:dhikr,target:target,count:next,haptic:haptic,
      history:next==target?List.unmodifiable([TasbihSession(dhikr,target,now.toUtc()),...history].take(100)):history);
  }
  TasbihState reset()=>TasbihState(dhikr:dhikr,target:target,haptic:haptic,history:history);
  TasbihState configure(Dhikr value,int goal){
    if(goal<1||goal>9999)throw RangeError.range(goal,1,9999);
    if(value==dhikr&&goal==target)return this;
    return TasbihState(dhikr:value,target:goal,haptic:haptic,history:history);
  }
  TasbihState vibration(bool value)=>TasbihState(dhikr:dhikr,target:target,count:count,haptic:value,history:history);
  TasbihState clearHistory()=>TasbihState(dhikr:dhikr,target:target,count:count,haptic:haptic);
  Map<String,dynamic> toJson()=>{'dhikr':dhikr.name,'target':target,'count':count,'haptic':haptic,'history':history.map((s)=>s.toJson()).toList()};
  factory TasbihState.fromJson(Map<String,dynamic> j){
    final target=j['target'] as int,count=j['count'] as int;
    if(target<1||target>9999||count<0||count>target)throw const FormatException('Invalid counter');
    return TasbihState(dhikr:Dhikr.values.byName(j['dhikr'] as String),target:target,count:count,haptic:j['haptic'] as bool,
      history:List.unmodifiable((j['history'] as List).take(100).map((x)=>TasbihSession.fromJson(Map<String,dynamic>.from(x as Map)))));
  }
}
