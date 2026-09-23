// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Proof of Handover
/// @notice Mencatat serah terima barang antara penjual dan pembeli secara permanen.
///         Penjual membuat catatan, pembeli yang ditunjuk mengonfirmasi dari wallet-nya.
/// @dev Kontrak ini tidak menyimpan atau memproses dana (tidak ada fungsi payable).
///      ID catatan dimulai dari 1.
contract ProofOfHandover {
    // ---------------------------------------------------------------
    // Data
    // ---------------------------------------------------------------

    struct Handover {
        address seller;
        address buyer;
        string itemName;
        string condition;
        string price;
        uint256 createdAt;
        uint256 confirmedAt;
        bool isConfirmed;
    }

    /// @notice Jumlah seluruh catatan yang pernah dibuat (sekaligus ID terakhir).
    uint256 public totalHandovers;

    mapping(uint256 => Handover) private handovers;

    // Batas panjang input supaya biaya gas tetap wajar dan tidak bisa disalahgunakan.
    uint256 public constant MAX_ITEM_NAME = 100;
    uint256 public constant MAX_CONDITION = 300;
    uint256 public constant MAX_PRICE = 50;

    // ---------------------------------------------------------------
    // Event
    // ---------------------------------------------------------------

    event HandoverCreated(
        uint256 indexed id,
        address indexed seller,
        address indexed buyer,
        string itemName
    );

    event HandoverConfirmed(
        uint256 indexed id,
        address indexed buyer,
        uint256 confirmedAt
    );

    // ---------------------------------------------------------------
    // Fungsi tulis
    // ---------------------------------------------------------------

    /// @notice Penjual membuat catatan serah terima baru.
    /// @param buyer Alamat wallet pembeli yang berhak mengonfirmasi.
    /// @param itemName Nama barang, misalnya "iPhone 13 128GB".
    /// @param condition Kondisi barang saat diserahkan.
    /// @param price Harga kesepakatan, ditulis bebas, misalnya "Rp 5.500.000".
    /// @return id ID catatan yang baru dibuat.
    function createHandover(
        address buyer,
        string memory itemName,
        string memory condition,
        string memory price
    ) external returns (uint256 id) {
        require(buyer != address(0), "Alamat pembeli tidak valid");
        require(buyer != msg.sender, "Penjual tidak boleh jadi pembeli");

        require(bytes(itemName).length > 0, "Nama barang wajib diisi");
        require(bytes(itemName).length <= MAX_ITEM_NAME, "Nama barang terlalu panjang");
        require(bytes(condition).length <= MAX_CONDITION, "Kondisi terlalu panjang");
        require(bytes(price).length <= MAX_PRICE, "Harga terlalu panjang");

        id = ++totalHandovers;

        Handover storage h = handovers[id];
        h.seller = msg.sender;
        h.buyer = buyer;
        h.itemName = itemName;
        h.condition = condition;
        h.price = price;
        h.createdAt = block.timestamp;

        emit HandoverCreated(id, msg.sender, buyer, itemName);
    }

    /// @notice Pembeli yang ditunjuk mengonfirmasi bahwa barang sudah diterima.
    /// @dev Hanya bisa dilakukan sekali. Setelah itu catatan terkunci selamanya.
    /// @param id ID catatan yang dikonfirmasi.
    function confirmHandover(uint256 id) external {
        require(_exists(id), "Catatan tidak ditemukan");

        Handover storage h = handovers[id];
        require(msg.sender == h.buyer, "Hanya pembeli yang bisa konfirmasi");
        require(!h.isConfirmed, "Sudah dikonfirmasi sebelumnya");

        h.isConfirmed = true;
        h.confirmedAt = block.timestamp;

        emit HandoverConfirmed(id, msg.sender, block.timestamp);
    }

    // ---------------------------------------------------------------
    // Fungsi baca
    // ---------------------------------------------------------------

    /// @notice Membaca seluruh isi catatan. Bisa dipanggil siapa saja tanpa biaya.
    function getHandover(uint256 id) external view returns (Handover memory) {
        require(_exists(id), "Catatan tidak ditemukan");
        return handovers[id];
    }

    // ---------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------

    function _exists(uint256 id) internal view returns (bool) {
        return id > 0 && id <= totalHandovers;
    }
}
