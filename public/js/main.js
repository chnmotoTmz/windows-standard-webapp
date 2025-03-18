// アプリケーションのメインクラス
class BookManager {
    constructor() {
        this.api = new BookAPI();
        this.currentBook = null;
        this.initializeElements();
        this.attachEventListeners();
        this.loadBooks();
    }

    // DOM要素の初期化
    initializeElements() {
        // 検索関連
        this.searchInput = document.getElementById('searchInput');
        this.searchButton = document.getElementById('searchButton');
        this.addBookButton = document.getElementById('addBookButton');

        // 本のリスト
        this.booksList = document.getElementById('booksList');

        // モーダル関連
        this.modal = document.getElementById('bookModal');
        this.modalTitle = document.getElementById('modalTitle');
        this.bookForm = document.getElementById('bookForm');
        this.bookId = document.getElementById('bookId');
        this.title = document.getElementById('title');
        this.author = document.getElementById('author');
        this.publisher = document.getElementById('publisher');
        this.publishedDate = document.getElementById('publishedDate');
        this.isbn = document.getElementById('isbn');
        this.saveButton = document.getElementById('saveButton');
        this.cancelButton = document.getElementById('cancelButton');
    }

    // イベントリスナーの設定
    attachEventListeners() {
        // 検索ボタンのクリック
        this.searchButton.addEventListener('click', () => this.handleSearch());

        // 検索入力のEnterキー
        this.searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.handleSearch();
            }
        });

        // 新規登録ボタンのクリック
        this.addBookButton.addEventListener('click', () => this.showModal());

        // フォームの送信
        this.bookForm.addEventListener('submit', (e) => this.handleSubmit(e));

        // キャンセルボタンのクリック
        this.cancelButton.addEventListener('click', () => this.hideModal());
    }

    // 本の一覧を読み込む
    async loadBooks() {
        try {
            const books = await this.api.getBooks();
            this.displayBooks(books);
        } catch (error) {
            this.showError('本の一覧の読み込みに失敗しました');
        }
    }

    // 本の一覧を表示
    displayBooks(books) {
        this.booksList.innerHTML = '';
        books.forEach(book => {
            const card = this.createBookCard(book);
            this.booksList.appendChild(card);
        });
    }

    // 本のカードを作成
    createBookCard(book) {
        const card = document.createElement('div');
        card.className = 'book-card';
        card.innerHTML = `
            <h3>${book.title}</h3>
            <div class="book-info">
                <p>著者: ${book.author}</p>
                <p>出版社: ${book.publisher}</p>
                <p>出版日: ${book.publishedDate}</p>
                <p>ISBN: ${book.isbn}</p>
            </div>
            <div class="book-actions">
                <button class="edit-button">編集</button>
                <button class="delete-button">削除</button>
            </div>
        `;

        // 編集ボタンのイベント
        card.querySelector('.edit-button').addEventListener('click', () => {
            this.currentBook = book;
            this.showModal();
        });

        // 削除ボタンのイベント
        card.querySelector('.delete-button').addEventListener('click', () => {
            this.handleDelete(book.id);
        });

        return card;
    }

    // 検索の処理
    async handleSearch() {
        const keyword = this.searchInput.value.trim();
        if (!keyword) {
            this.loadBooks();
            return;
        }

        try {
            const books = await this.api.searchBooks(keyword);
            this.displayBooks(books);
        } catch (error) {
            this.showError('検索に失敗しました');
        }
    }

    // モーダルを表示
    showModal() {
        this.modalTitle.textContent = this.currentBook ? '本の編集' : '本の登録';
        if (this.currentBook) {
            this.bookId.value = this.currentBook.id;
            this.title.value = this.currentBook.title;
            this.author.value = this.currentBook.author;
            this.publisher.value = this.currentBook.publisher;
            this.publishedDate.value = this.currentBook.publishedDate;
            this.isbn.value = this.currentBook.isbn;
        } else {
            this.bookForm.reset();
            this.bookId.value = '';
        }
        this.modal.style.display = 'block';
    }

    // モーダルを非表示
    hideModal() {
        this.modal.style.display = 'none';
        this.currentBook = null;
        this.bookForm.reset();
    }

    // フォームの送信処理
    async handleSubmit(e) {
        e.preventDefault();
        const book = {
            title: this.title.value,
            author: this.author.value,
            publisher: this.publisher.value,
            publishedDate: this.publishedDate.value,
            isbn: this.isbn.value
        };

        try {
            if (this.currentBook) {
                book.id = this.currentBook.id;
                await this.api.updateBook(book);
            } else {
                await this.api.addBook(book);
            }
            this.hideModal();
            this.loadBooks();
        } catch (error) {
            this.showError('保存に失敗しました');
        }
    }

    // 削除の処理
    async handleDelete(id) {
        if (!confirm('この本を削除してもよろしいですか？')) {
            return;
        }

        try {
            await this.api.deleteBook(id);
            this.loadBooks();
        } catch (error) {
            this.showError('削除に失敗しました');
        }
    }

    // エラーメッセージを表示
    showError(message) {
        alert(message);
    }
}

// アプリケーションの初期化
document.addEventListener('DOMContentLoaded', () => {
    new BookManager();
}); 