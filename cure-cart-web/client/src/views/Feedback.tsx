import { useEffect, useState } from 'react'
import axios from 'axios'
import { Star, TrendingUp, Users, MessageSquare, Trash2 } from 'lucide-react'

type PharmacyFeedback = { 
  _id: string; 
  rating: number; 
  comment?: string; 
  createdAt: string;
  customerName?: string;
  customerEmail?: string;
}

type FeedbackStats = {
  averageRating: number;
  totalReviews: number;
}

export default function Feedback() {
  const [items, setItems] = useState<PharmacyFeedback[]>([])
  const [stats, setStats] = useState<FeedbackStats>({ averageRating: 0, totalReviews: 0 })
  const [loading, setLoading] = useState(true)
  const [pharmacyId, setPharmacyId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState<string | null>(null)

  useEffect(() => {
    const loadFeedback = async () => {
      try {
        setLoading(true)
        
        // First, get the current user's pharmacy
        const { data: pharmacy } = await axios.get('/api/pharmacies/me')
        console.log('🔍 [FEEDBACK] Pharmacy data:', pharmacy)
        if (pharmacy?._id) {
          setPharmacyId(pharmacy._id)
          console.log('🔍 [FEEDBACK] Loading feedback for pharmacy:', pharmacy._id)
          
          // Load pharmacy-specific feedback
          const { data: feedbackData } = await axios.get(`/api/pharmacy-feedback/${pharmacy._id}`)
          console.log('🔍 [FEEDBACK] Feedback data:', feedbackData)
          setItems(feedbackData.feedback || [])
          setStats(feedbackData.stats || { averageRating: 0, totalReviews: 0 })
        } else {
          // Fallback to general feedback if no pharmacy
          const { data } = await axios.get('/api/feedback')
          setItems(data || [])
        }
      } catch (error) {
        console.error('Error loading feedback:', error)
        // Fallback to general feedback
        try {
          const { data } = await axios.get('/api/feedback')
          setItems(data || [])
        } catch (fallbackError) {
          console.error('Error loading fallback feedback:', fallbackError)
        }
      } finally {
        setLoading(false)
      }
    }
    
    loadFeedback()
  }, [])

  const handleDeleteFeedback = async (feedbackId: string) => {
    if (!confirm('Are you sure you want to delete this feedback? This action cannot be undone.')) {
      return
    }

    try {
      setDeleting(feedbackId)
      await axios.delete(`/api/pharmacy-feedback/${feedbackId}`)
      
      // Remove the deleted feedback from the list
      setItems(prev => prev.filter(item => item._id !== feedbackId))
      
      // Recalculate stats
      const remainingItems = items.filter(item => item._id !== feedbackId)
      const newStats = {
        averageRating: remainingItems.length > 0 
          ? Math.round((remainingItems.reduce((sum, item) => sum + item.rating, 0) / remainingItems.length) * 10) / 10
          : 0,
        totalReviews: remainingItems.length
      }
      setStats(newStats)
      
      console.log('✅ Feedback deleted successfully')
    } catch (error) {
      console.error('❌ Error deleting feedback:', error)
      alert('Failed to delete feedback. Please try again.')
    } finally {
      setDeleting(null)
    }
  }
  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-yellow-500 to-amber-500 shadow-lg">
            <Star className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Customer Feedback</h2>
        </div>
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-500"></div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-gradient-to-br from-yellow-500 to-amber-500 shadow-lg">
          <Star className="w-6 h-6 text-white" />
        </div>
        <h2 className="text-2xl font-bold text-slate-900">
          {pharmacyId ? 'Pharmacy Feedback' : 'Customer Feedback'}
        </h2>
      </div>

      {/* Stats Section */}
      {pharmacyId && stats.totalReviews > 0 && (
        <div className="grid md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-gradient-to-br from-yellow-500 to-amber-500">
                <Star className="w-5 h-5 text-white" />
              </div>
              <div>
                <div className="text-2xl font-bold text-slate-900">{stats.averageRating.toFixed(1)}</div>
                <div className="text-sm text-slate-600">Average Rating</div>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600">
                <Users className="w-5 h-5 text-white" />
              </div>
              <div>
                <div className="text-2xl font-bold text-slate-900">{stats.totalReviews}</div>
                <div className="text-sm text-slate-600">Total Reviews</div>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-gradient-to-br from-green-500 to-green-600">
                <MessageSquare className="w-5 h-5 text-white" />
              </div>
              <div>
                <div className="text-2xl font-bold text-slate-900">{items.length}</div>
                <div className="text-sm text-slate-600">Recent Reviews</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Feedback List */}
      {items.length === 0 ? (
        <div className="bg-white rounded-xl border border-slate-200 p-12 text-center">
          <div className="text-slate-400 mb-4">
            <Star className="w-12 h-12 mx-auto" />
          </div>
          <h3 className="text-lg font-semibold text-slate-900 mb-2">No feedback yet</h3>
          <p className="text-slate-600">
            {pharmacyId 
              ? 'No customers have rated your pharmacy yet. Encourage customers to leave feedback!'
              : 'No feedback available at the moment.'
            }
          </p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 gap-6">
          {items.map(f => (
            <div key={f._id} className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg hover:shadow-xl transition-all duration-300 relative overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-br from-yellow-500/5 to-amber-500/5 rounded-xl"></div>
              <div className="relative">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <Star 
                        key={i} 
                        className={`w-5 h-5 ${
                          i < f.rating ? 'text-yellow-400 fill-current' : 'text-gray-300'
                        }`} 
                      />
                    ))}
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="text-xs text-slate-500 font-medium">
                      {new Date(f.createdAt).toLocaleString()}
                    </div>
                    <button
                      onClick={() => handleDeleteFeedback(f._id)}
                      disabled={deleting === f._id}
                      className="p-1.5 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Delete feedback"
                    >
                      {deleting === f._id ? (
                        <div className="w-4 h-4 border-2 border-red-500 border-t-transparent rounded-full animate-spin"></div>
                      ) : (
                        <Trash2 className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
                
                {f.customerName && (
                  <div className="text-sm font-medium text-slate-900 mb-2">
                    {f.customerName}
                  </div>
                )}
                
                <div className="text-slate-700 text-sm leading-relaxed">
                  {f.comment || 'No comment provided'}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}


