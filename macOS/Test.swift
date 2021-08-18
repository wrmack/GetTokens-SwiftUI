//
//  Test.swift
//  GetTokens-SwiftUI (iOS)
//
//  Created by Warwick McNaughton on 18/08/21.
//

import SwiftUI

struct Test: View {
    var body: some View {
        VStack {
            ScrollView {

                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/).background(Color.green)
                .background(Color.red)
                .border(Color.blue,width:3)
                Text("Hello, World!")
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.white)
        }
        .background(Color.white)
    }
}

struct Test_Previews: PreviewProvider {
    static var previews: some View {
        Test()
    }
}
