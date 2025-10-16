import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <h1>DGTT Auto-École - Interface Candidat</h1>
      </div>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Projet React avec TypeScript
        </p>
      </div>
      <p className="read-the-docs">
        Cliquez sur le bouton pour tester
      </p>
    </>
  )
}

export default App

