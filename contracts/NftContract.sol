// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract NftContract is ERC721, Ownable {
    using Strings for uint256;

    // =================================
	// Storage
	// =================================

    uint256 public constant maxSupply = 1000;
    uint256 public numMinted;  

    bool public saleIsActive = true;

    // =================================
	// Metadata
	// =================================

    function generateHTMLandSVG() internal pure returns (string memory Html, string memory Svg) {
        Html = '<!DOCTYPE html> <html> <head> <title>Cats Jump</title> <meta charset="UTF-8" /> <style> html, body { height: 100%; margin: 0; } body { display: flex; align-items: center; justify-content: center; } canvas { border: 1px solid black; background-color: black; } </style> </head> <body> <canvas width="350" height="350" id="game"></canvas> <div> Score: <span id="score">0</span> </div> <script> const canvas = document.getElementById("game"); const context = canvas.getContext("2d"); const img = new Image(); img.src = "data:image/png;base64,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"; const platformWidth = 50; const platformHeight = 7; const platformStart = canvas.height - 70; const gravity = 0.33; const drag = 0.8; const bounceVelocity = -12.5; let minPlatformSpace = 40; let maxPlatformSpace = 60; let score = 0; let platforms = [ { x: canvas.width / 2 - platformWidth / 2, y: platformStart, }, ]; function random(min, max) { return Math.random() * (max - min) + min; } let y = platformStart; while (y > 0) { y -= platformHeight + random(minPlatformSpace, maxPlatformSpace); let x; do { x = random(25, canvas.width - 25 - platformWidth); } while ( y > canvas.height / 2 && x > canvas.width / 2 - platformWidth * 1.5 && x < canvas.width / 2 + platformWidth / 2 ); platforms.push({ x, y }); } const doodle = { width: 80, height: 55, x: canvas.width / 2 - 20, y: platformStart - 60, dx: 0, dy: 0, }; let playerDir = 0; let keydown = false; let prevDoodleY = doodle.y; img.onload = function () { function loop() { requestAnimationFrame(loop); context.clearRect(0, 0, canvas.width, canvas.height); doodle.dy += gravity; if (doodle.y < canvas.height / 2 && doodle.dy < 0) { platforms.forEach(function (platform) { platform.y += -doodle.dy; }); while (platforms[platforms.length - 1].y > 0) { platforms.push({ x: random(25, canvas.width - 25 - platformWidth), y: platforms[platforms.length - 1].y - (platformHeight + random(minPlatformSpace, maxPlatformSpace)), }); minPlatformSpace += 0.5; maxPlatformSpace += 0.5; maxPlatformSpace = Math.min(maxPlatformSpace, canvas.height / 2); } } else { doodle.y += doodle.dy; } if (!keydown) { if (playerDir < 0) { doodle.dx += drag; if (doodle.dx > 0) { doodle.dx = 0; playerDir = 0; } } else if (playerDir > 0) { doodle.dx -= drag; if (doodle.dx < 0) { doodle.dx = 0; playerDir = 0; } } } doodle.x += doodle.dx; if (doodle.x + doodle.width < 0) { doodle.x = canvas.width; } else if (doodle.x > canvas.width) { doodle.x = -doodle.width; } context.fillStyle = "white"; platforms.forEach(function (platform) { context.fillRect( platform.x, platform.y, platformWidth, platformHeight ); if ( doodle.dy > 0 && prevDoodleY + doodle.height <= platform.y && doodle.x < platform.x + platformWidth && doodle.x + doodle.width > platform.x && doodle.y < platform.y + platformHeight && doodle.y + doodle.height > platform.y ) { doodle.y = platform.y - doodle.height; doodle.dy = bounceVelocity; updateScore() } }); context.drawImage(img, doodle.x, doodle.y, doodle.width, doodle.height); prevDoodleY = doodle.y; platforms = platforms.filter(function (platform) { return platform.y < canvas.height; }); } requestAnimationFrame(loop); }; const scoreElement = document.getElementById("score"); function updateScore() { score++; scoreElement.textContent = score; } document.addEventListener("keydown", function (e) { if (e.which === 37) { keydown = true; playerDir = -1; doodle.dx = -3; } else if (e.which === 39) { keydown = true; playerDir = 1; doodle.dx = 3; } else if (e.which === 32) { platforms = [{ x: canvas.width / 2 - platformWidth / 2, y: platformStart }]; minPlatformSpace = 40; maxPlatformSpace = 60; doodle.x = canvas.width / 2 - 20; doodle.y = platformStart - 60; doodle.dx = 0; doodle.dy = 0; score = 0; } }); document.addEventListener("keyup", function (e) { keydown = false; }); requestAnimationFrame(loop); </script> </body> </html>';
        Svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><rect width="256" height="256" fill="none"/><line x1="128" y1="192" x2="128" y2="224" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/><circle cx="84" cy="140" r="8"/><circle cx="172" cy="140" r="8"/><line x1="128" y1="48" x2="128" y2="88" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/><polyline points="144 176 128 192 112 176" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/><line x1="96" y1="53" x2="96" y2="88" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/><line x1="160" y1="53" x2="160" y2="88" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/><path d="M32,136V51.3a8,8,0,0,1,13.7-5.6L67.6,67.6h0A100.8,100.8,0,0,1,128,48a100.8,100.8,0,0,1,60.4,19.6h0l21.9-21.9A8,8,0,0,1,224,51.3V136c0,48.6-43,88-96,88S32,184.6,32,136Z" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="8"/></svg>';
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function htmlToImageURI(string memory html) internal pure returns (string memory) {
        string memory baseURL = "data:text/html;base64,";
        string memory htmlBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(html))));
        return string(abi.encodePacked(baseURL,htmlBase64Encoded));
    }

    function svgToImageURI(string memory svg) internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        (string memory html, string memory svg) = generateHTMLandSVG();

        string memory imageURIhtml = htmlToImageURI(html);
        string memory imageURIsvg = svgToImageURI(svg);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "CatJ | ", uint2str(tokenId),"",
                                '", "description":"left arrow and right arrow - move, space - start again", "attributes":"cat", "image":"', imageURIsvg,'", "animation_url":"', imageURIhtml,'"}'
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // =================================
	// Mint
	// =================================

    function mint(address _to) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numMinted < maxSupply, "Sale has already ended");

        numMinted += 1;
        _safeMint(_to, numMinted);
    }

    // =================================
	// Owner functions
	// =================================

    function setSaleStatus(bool state) public onlyOwner {
        saleIsActive = state;
    }

    // =================================
	// Constructor
	// =================================
    
    constructor() ERC721("Cats jump", "CJUMP") {
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
    }

}
