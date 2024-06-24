//
//  WritingStrings.swift
//  ENGL2880-AR_Book
//
//  Created by Spencer Dunn on 5/7/24.
//

import Foundation

class StringFinder {
    var types = ["Brick", "WhiteCinderblock", "Windows", "Wood", "WoodenDoors"]
    var quotes : [[String]] = []
    
    let brick_quotes = [
        "\"I would prefer not to\" - Herman Melville, Bartleby the Scrivener",
        "\"yet I had never seen him reading—no, not even a newspaper; that for long periods he would stand looking out, at his pale window behind the screen, upon the dead brick wall\" - Herman Melville, Bartleby the Scrivener",
        "\"People who get up early in the morning cause war, death and famine.\" - Banksy, Banging Your Head Against a Brick Wall"
    ]
    let white_cinderblock_quotes = [
        "\"General Secretary Gorbachev, if you seek peace, if you seek prosperity for the Soviet Union and Eastern Europe, if you seek liberalization: Come here to this gate! Mr. Gorbachev, open this gate! Mr. Gorbachev, tear down this wall!\" - Ronald Reagan, The Berlin Wall Speech",
        "\"Walls installed to segregate will only generate hate, and never separate the people from the problems they create.\" - Martin Powell",
        "\"Nobody has the intention of building a wall.\" - Walter Ulbricht, head of the GDR two months before construction began",
        "\"Many small people, who in many small places do many small things, can alter the face of the world.\" -  East Side Gallery, Berlin, 1990"
    ]
    let windows_quotes = [
        "\"What one can see out in the sunlight is always less interesting than what goes on behind a windowpane. In that black or luminous square life lives, life dreams, life suffers.\" - Charles Baudelaire, Windows",
        "\"The places I see outside reminds me of my desire To explore and travel is a dream I longed and aspire. A dream that’ll stay with me even when my life expires My raison d’être, my purpose, the goal I’m inspired...\" - Wei-Chih Eudela, The Window",
        "\"For when I look out my window…nature’s art is what I see…I love the vibrant colors she uses to paint her birds, her flowers…her trees.\" - Jim Yerman, Window Art Poem",
        "\"The world has different owners at sunrise... Even your own garden does not belong to you, Rabbits and blackbirds have the lawns; a tortoise-shell cat who never appears in daytime patrols the brick walls, and a golden-tailed pheasant glints his way through this iris spears.\" - Anne Morrow Lindbergh"
    ]
    let wood_quotes = [
        "\"The acorn's not yet fallen from the tree, That's to grow the wood, That's to make the cradle, That's to rock the bairn, That's to grow the man, That's to lay me.\" - The Cauld Lad of Hilton",
        "\"Oh, finally I sing the praises of wood. Homegrown and handy, abundant, convenient, cheap, the growth of these hills right here at home. Finally now, I sing the praises of our hardwood trees.\" - David Budbill, Ode to Wood"
    ]
    let wooden_doors_quotes = [
        "\"Sometimes you don’t know when you’re taking the first step through a door until you’re already inside.\" - Ann Voskamp, One Thousand Gifts: A Dare to Live Fully Right Where You Are",
        "\"There will always be a door to the light.\" - Shiro Amano, Kingdom Hearts, Vol. 1",
        "\"When slightly open, a door is ajar, but when slightly open, is a jar adoor?\" - Jarod Kintz, 94,000 Wasps in a Trench Coat"
    ]
    
    init() {
        self.quotes = [brick_quotes, white_cinderblock_quotes, windows_quotes, wood_quotes, wooden_doors_quotes]
        //self.types = types
    }
    
    func return_writing_strings(environmentDesc : String) -> String{
        // Types:
        for i in 1...types.count {
            if types[i-1] == environmentDesc {
                return self.quotes[i-1].randomElement() ?? "Error Retreiving String"
            }
        }
        
        
        return "No String Found"
    }
}

