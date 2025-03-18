/**
 * 本管理用のAPIクライアントクラス
 */
class BookAPI {
    /**
     * コンストラクタ
     */
    constructor() {
        this.apiUrl = '/api/books';
    }

    /**
     * 本の一覧を取得
     * @returns {Promise<Array>} 本の配列
     */
    async getBooks() {
        try {
            const response = await fetch(this.apiUrl);
            if (!response.ok) {
                throw new Error('API request failed');
            }
            return await response.json();
        } catch (error) {
            console.error('本の取得に失敗しました:', error);
            return [];
        }
    }

    /**
     * 新しい本を追加
     * @param {Object} book 本のデータ
     * @returns {Promise<Object>} 追加された本
     */
    async addBook(book) {
        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(book)
            });
            
            if (!response.ok) {
                throw new Error('API request failed');
            }
            
            return await response.json();
        } catch (error) {
            console.error('本の追加に失敗しました:', error);
            throw error;
        }
    }

    /**
     * 本を更新
     * @param {Object} book 更新する本のデータ
     * @returns {Promise<boolean>} 成功したかどうか
     */
    async updateBook(book) {
        try {
            const response = await fetch(this.apiUrl, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(book)
            });
            
            return response.ok;
        } catch (error) {
            console.error('本の更新に失敗しました:', error);
            throw error;
        }
    }

    /**
     * 本を削除
     * @param {number} id 削除する本のID
     * @returns {Promise<boolean>} 成功したかどうか
     */
    async deleteBook(id) {
        try {
            const response = await fetch(`${this.apiUrl}?id=${id}`, {
                method: 'DELETE'
            });
            
            return response.ok;
        } catch (error) {
            console.error('本の削除に失敗しました:', error);
            throw error;
        }
    }

    /**
     * 本を検索
     * @param {string} keyword 検索キーワード
     * @returns {Promise<Array>} 検索結果の本の配列
     */
    async searchBooks(keyword) {
        try {
            const books = await this.getBooks();
            const lowerKeyword = keyword.toLowerCase();
            
            return books.filter(book => 
                book.title.toLowerCase().includes(lowerKeyword) ||
                book.author.toLowerCase().includes(lowerKeyword) ||
                book.publisher.toLowerCase().includes(lowerKeyword)
            );
        } catch (error) {
            console.error('本の検索に失敗しました:', error);
            return [];
        }
    }
} 