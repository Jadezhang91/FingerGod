//
//  ModelReader.swift
//  FingerGod
//
//  Created by Aaron Freytag on 2018-02-21.
//  Copyright © 2018 Ramen Interactive. All rights reserved.
//

import Foundation
import GLKit

public class ModelReader {
    enum ModelReaderError : Error {
        case ResourceNotFound(file: String)
    }
    public static func read(objPath: String) throws -> Model {
        let path = Bundle.main.path(forResource: objPath, ofType: "obj")
        if (path == nil) {
            throw ModelReaderError.ResourceNotFound(file: objPath)
        }
        let objFile = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        
        var baseVertices = [GLfloat]()
        var faceNormals = [GLfloat]()
        var texels = [GLfloat]()
        var faces = [[Int]]()

        objFile.enumerateLines { line, _ in
            switch (line.prefix(2)) {
            case "v ":
                baseVertices += parseVertex(line: line)
            case "vt":
                texels += parseTexel(line: line)
            case "vn":
                faceNormals += parseNormal(line: line)
            case "f ":
                faces += parseFace(line: line)
            default:
                break
            }
        }
        
        // Now that we have the data from the file, we need to convert it into a format OpenGL can use
        // Basically, this just involves duplicating vertices that have multiple normals
        
        var vertices = [GLfloat]()
        var normals = [GLfloat]()
        var indices = [GLint]()
        
        var indexDictionary = [String:Int]()
        for f in faces {
            let txt = String("\(f[0])/\(f[1])")
            if (indexDictionary[txt] == nil) {
                // This vertex-normal pair has never been used before, so make the vertex and put it in the dictionary
                let ind = vertices.count / 3
                vertices.append(baseVertices[f[0] * 3])
                vertices.append(baseVertices[f[0] * 3 + 1])
                vertices.append(baseVertices[f[0] * 3 + 2])
                normals.append(faceNormals[f[1] * 3])
                normals.append(faceNormals[f[1] * 3 + 1])
                normals.append(faceNormals[f[1] * 3 + 2])
                indexDictionary[txt] = ind
            }
            indices.append(GLint(indexDictionary[txt]!))
        }
        
        return Model(vertices: vertices, normals: normals, texels: texels, faces: indices)
    }
    
    private static func parseVertex(line: String) -> [GLfloat] {
        let sc = Scanner(string: line)
        sc.charactersToBeSkipped = CharacterSet(charactersIn: "v ")
        var dec = Float(0.0)
        var vals = [GLfloat]()
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        return vals;
    }
    
    private static func parseTexel(line: String) -> [GLfloat] {
        let sc = Scanner(string: line)
        sc.charactersToBeSkipped = CharacterSet(charactersIn: "vt ")
        var dec = Float(0.0)
        var vals = [GLfloat]()
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        return vals;
    }
    
    private static func parseNormal(line: String) -> [GLfloat] {
        let sc = Scanner(string: line)
        sc.charactersToBeSkipped = CharacterSet(charactersIn: "vn ")
        var dec = Float(0.0)
        var vals = [GLfloat]()
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        sc.scanFloat(&dec)
        vals.append(dec)
        return vals;
    }
    
    private static func parseFace(line: String) -> [[Int]] {
        let sc = Scanner(string: line)
        sc.charactersToBeSkipped = CharacterSet(charactersIn: "f/ ")
        var vec = Int(0.0)
        var nor = Int(0.0)
        var vals = [[Int]]()
        sc.scanInt(&vec)
        sc.scanInt(&nor)
        vals.append([vec - 1, nor - 1])
        sc.scanInt(&vec)
        sc.scanInt(&nor)
        vals.append([vec - 1, nor - 1])
        sc.scanInt(&vec)
        sc.scanInt(&nor)
        vals.append([vec - 1, nor - 1])
        return vals
    }
}
