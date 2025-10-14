import { useEffect, useState } from 'react'
import axios from 'axios'
import { MessageCircle, Send, Building2, Trash2 } from 'lucide-react'

interface ChatMessage {
  _id: string
  message: string
  senderId: string
  senderName: string
  senderType: 'patient' | 'pharmacist'
  createdAt: string
  isRead: boolean
}

export default function Chat() {
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [newMessage, setNewMessage] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isSending, setIsSending] = useState(false)
  const [pharmacyId, setPharmacyId] = useState<string | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)

  useEffect(() => {
    const loadPharmacyAndMessages = async () => {
      try {
        setIsLoading(true)
        
        // Get pharmacy info
        const { data: pharmacy } = await axios.get('/api/pharmacies/me')
        console.log('🔍 [CHAT] Pharmacy data:', pharmacy)
        
        if (pharmacy?._id) {
          setPharmacyId(pharmacy._id)
          
          // Load all chat messages for this pharmacy
          const { data: chatData } = await axios.get(`/api/chat/${pharmacy._id}`)
          console.log('🔍 [CHAT] Messages:', chatData)
          setMessages(chatData.messages || [])
          
          // Mark all patient messages as read when pharmacist opens chat
          try {
            await axios.patch(`/api/chat/${pharmacy._id}/read`)
            console.log('✅ [CHAT] Messages marked as read')
          } catch (error) {
            console.error('❌ [CHAT] Error marking messages as read:', error)
          }
        }
      } catch (error) {
        console.error('❌ Error loading chat:', error)
      } finally {
        setIsLoading(false)
      }
    }

    loadPharmacyAndMessages()
  }, [])

  const sendMessage = async () => {
    if (!newMessage.trim() || !pharmacyId || isSending) return

    const messageText = newMessage.trim()
    setNewMessage('')
    setIsSending(true)

    try {
      const { data: user } = await axios.get('/api/auth/me')

      const response = await axios.post(`/api/chat/${pharmacyId}`, {
        message: messageText,
        senderId: user._id,
        senderName: user.name || 'Pharmacist',
        senderType: 'pharmacist'
      })

      if (response.data.message) {
        setMessages(prev => [...prev, response.data.message])
      }
    } catch (error) {
      console.error('❌ Error sending message:', error)
      setNewMessage(messageText) // Restore message on error
    } finally {
      setIsSending(false)
    }
  }

  const deleteChat = async () => {
    if (!pharmacyId || isDeleting) return

    const confirmed = window.confirm('Are you sure you want to delete all chat messages? This action cannot be undone.')
    if (!confirmed) return

    setIsDeleting(true)

    try {
      await axios.delete(`/api/chat/${pharmacyId}`)
      setMessages([])
      console.log('✅ Chat messages deleted successfully')
    } catch (error) {
      console.error('❌ Error deleting chat messages:', error)
      alert('Failed to delete chat messages. Please try again.')
    } finally {
      setIsDeleting(false)
    }
  }

  const formatTime = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    
    if (diff < 60000) return 'Just now'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
    return date.toLocaleDateString()
  }

  if (isLoading) {
    return (
      <div className="bg-white border border-slate-200 rounded-lg p-6">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </div>
    )
  }

  if (!pharmacyId) {
    return (
      <div className="bg-white border border-slate-200 rounded-lg p-6">
        <div className="text-center text-slate-500">
          <MessageCircle className="w-12 h-12 mx-auto mb-4 text-slate-300" />
          <h3 className="text-lg font-medium mb-2">No Pharmacy Found</h3>
          <p>You need to be associated with a pharmacy to access chat.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white border border-slate-200 rounded-lg overflow-hidden flex flex-col h-[600px]">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 text-white p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-white/20 rounded-lg">
              <MessageCircle className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-semibold">Chat Support</h2>
              <p className="text-sm text-blue-100">Communicate with patients</p>
            </div>
          </div>
          {messages.length > 0 && (
            <button
              onClick={deleteChat}
              disabled={isDeleting}
              className="flex items-center gap-2 px-3 py-2 bg-red-500/20 hover:bg-red-500/30 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              title="Delete all chat messages"
            >
              {isDeleting ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              ) : (
                <Trash2 className="w-4 h-4" />
              )}
              <span className="text-sm">Delete Chat</span>
            </button>
          )}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 ? (
          <div className="text-center text-slate-500 py-8">
            <MessageCircle className="w-12 h-12 mx-auto mb-4 text-slate-300" />
            <h3 className="text-lg font-medium mb-2">No Messages Yet</h3>
            <p>Start a conversation with your patients.</p>
          </div>
        ) : (
          messages.map((message) => (
            <div
              key={message._id}
              className={`flex gap-3 ${
                message.senderType === 'pharmacist' ? 'flex-row-reverse' : ''
              }`}
            >
              {/* Avatar */}
              <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
                message.senderType === 'pharmacist'
                  ? 'bg-blue-600'
                  : 'bg-green-600'
              }`}>
                <Building2 className="w-4 h-4 text-white" />
              </div>

              {/* Message */}
              <div className={`flex-1 max-w-xs ${
                message.senderType === 'pharmacist' ? 'text-right' : ''
              }`}>
                <div className={`inline-block p-3 rounded-lg ${
                  message.senderType === 'pharmacist'
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-100 text-slate-900'
                }`}>
                  <p className="text-sm">{message.message}</p>
                </div>
                <div className="mt-1 text-xs text-slate-500">
                  {message.senderName} • {formatTime(message.createdAt)}
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Message Input */}
      <div className="border-t border-slate-200 p-4">
        <div className="flex gap-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
            placeholder="Type a message..."
            className="flex-1 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            disabled={isSending}
          />
          <button
            onClick={sendMessage}
            disabled={!newMessage.trim() || isSending}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {isSending ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            ) : (
              <Send className="w-4 h-4" />
            )}
          </button>
        </div>
      </div>
    </div>
  )
}